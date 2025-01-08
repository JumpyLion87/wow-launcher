import sys
import os
import subprocess
import platform
import configparser
import requests
import hashlib
import logging
import json
import socket
import threading
import time
from PyQt5.QtWidgets import QApplication, QFileDialog, QSystemTrayIcon, QMenu, QAction
from PyQt5.QtCore import (
    QThread, pyqtSignal, QObject, pyqtSlot, 
    pyqtProperty, QUrl, QTimer, QMetaObject, 
    QVariant, Q_ARG, Qt
)
from PyQt5.QtQml import QQmlApplicationEngine
from PyQt5.QtGui import QIcon
from typing import Optional

# Настройка логирования
logging.basicConfig(
    filename='launcher.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
)

class ConfigManager:
    def __init__(self, config_file: str = 'config.ini') -> None:
        self.logger = logging.getLogger(__name__)
        self.config_file = config_file
        self.config = configparser.ConfigParser()
        self.game_path = self.load_game_path()
        self.current_version = self.load_current_version()

    def load_game_path(self) -> Optional[str]:
        try:
            if os.path.exists(self.config_file):
                self.config.read(self.config_file)
                if 'Settings' in self.config and 'GamePath' in self.config['Settings']:
                    return self.config['Settings']['GamePath']
            return None
        except Exception as e:
            self.logger.error(f"Ошибка при загрузке пути к игре: {str(e)}")
            return None

    def save_game_path(self, path: str) -> bool:
        try:
            self.config['Settings'] = {
                'GamePath': path,
                'CurrentVersion': self.current_version
            }
            with open(self.config_file, 'w') as configfile:
                self.config.write(configfile)
            return True
        except Exception as e:
            self.logger.error(f"Ошибка при сохранении пути к игре: {str(e)}")
            return False

    def load_current_version(self) -> str:
        try:
            if os.path.exists(self.config_file):
                self.config.read(self.config_file)
                if 'Settings' in self.config and 'CurrentVersion' in self.config['Settings']:
                    return self.config['Settings']['CurrentVersion']
            return "3.3.5"
        except Exception as e:
            self.logger.error(f"Ошибка при загрузке версии: {str(e)}")
            return "3.3.5"

class DownloadManager(QThread):
    update_status = pyqtSignal(str)
    update_progress = pyqtSignal(float)
    update_file_name = pyqtSignal(str)
    update_speed = pyqtSignal(str)
    update_size_info = pyqtSignal(str) # Новый сигнал для отображения информации о размере файлов
    finished = pyqtSignal()

    def __init__(self, manifest_url: str, game_path: str, files_to_download=None):
        super().__init__()
        self.manifest_url = manifest_url
        self.game_path = game_path
        self.specific_files = files_to_download  # список конкретных файлов для загрузки
        self.is_downloading = True
        self.files_to_download = {}
        self.files_to_process = {}  # Файлы, которые нужно скачать
        self.corrupted_files = []
        self.logger = logging.getLogger(__name__)
        self.chunk_size = 8192
        self.current_downloaded = 0
        self.last_downloaded = 0
        self.resume_position = 0  # Позиция для возобновления загрузки
        self.speed_timer = QTimer()
        self.speed_timer.timeout.connect(self.calculate_speed)
        self.speed_timer.start(1000)  # Обновляем каждую секунду
        self.segment_size = 1024 * 1024 * 10 # 10 МБ сегменты
        self.max_retries = 3 # Максимальное количество попыток загрузки файла
        self.total_size = 0 # Общий размер всех файлов
        self.total_downloaded = 0 # Общий размер загруженных файлов
        self.current_speed = 0 # Текущая скорость загрузки        

    def check_existing_files(self):
        """Проверяет существующие файлы и их целостность"""
        try:
            response = requests.get(self.manifest_url)
            response.raise_for_status()
            manifest = response.json()['files']
            
            # Если указаны конкретные файлы, загружаем только их
            if self.specific_files:
                self.files_to_process = {
                    filename: manifest[filename]
                    for filename in self.specific_files
                    if filename in manifest
                }
            else:
                # Стандартная проверка всех файлов
                self.files_to_download = manifest
                self.files_to_process = {}

                for filename, file_info in self.files_to_download.items():
                    local_path = os.path.join(self.game_path, filename)
                    needs_download = True

                    if os.path.exists(local_path):
                        # Проверяем размер файла
                        actual_size = os.path.getsize(local_path)
                        if actual_size == file_info['size']:
                            # Проверяем хеш только если размер совпадает
                            if self.verify_checksum(local_path, file_info['hash']):
                                needs_download = False
                                self.logger.info(f'Файл {filename} проверен и корректен')
                                continue

                        self.logger.warning(f'Файл {filename} поврежден или неполон. Будет перезагружен')
                        if os.path.exists(local_path):
                            os.remove(local_path)

                    if needs_download:
                        self.files_to_process[filename] = file_info
                        self.logger.info(f'Файл {filename} добавлен в очередь загрузки')

        except Exception as e:
            self.logger.error(f"Ошибка при проверке файлов: {str(e)}")
            raise

    def stop(self):
        self.is_downloading = False
        self.speed_timer.stop()
        self.logger.info('Загрузка остановлена пользователем')

    def verify_checksum(self, file_path: str, expected_checksum: str) -> bool:
        try:
            sha256_hash = hashlib.sha256()
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
            return sha256_hash.hexdigest() == expected_checksum
        except Exception as e:
            self.logger.error(f"Ошибка при проверке контрольной суммы {file_path}: {e}")
            return False

    def calculate_speed(self):
        if hasattr(self, 'current_downloaded'):
            self.current_speed = self.current_downloaded - self.last_downloaded
            self.last_downloaded = self.current_downloaded
            if self.current_speed > 0: # Отправляем сигнал только если есть прогресс
                speed_str = f"{self.current_speed / (1024 * 1024):.1f} МБ/с" if self.current_speed > 1024 * 1024 else f"{self.current_speed / 1024:.1f} КБ/с"
                self.update_speed.emit(speed_str)
                # Обновляем информацию о размере файлов
                downloaded_gb = self.total_downloaded / (1024 * 1024 * 1024)
                total_gb = self.total_size / (1024 * 1024 * 1024)
                downloaded_str = f"{downloaded_gb:.2f}/{total_gb:.2f} ГБ"
                self.update_size_info.emit(downloaded_str)

    def download_file_segmented(self, url: str, local_path: str, file_size: int):
        temp_path = local_path + '.temp'
        downloaded_size = 0

        if os.path.exists(temp_path):
            downloaded_size = os.path.getsize(temp_path)
            self.total_downloaded += downloaded_size # Учитываем уже загруженный размер

        with open(temp_path, 'ab') as f:
            while downloaded_size < file_size:
                start = downloaded_size
                end = min(start + self.segment_size - 1, file_size - 1)
                
                for attempt in range(self.max_retries):
                    try:
                        headers = {'Range': f'bytes={start}-{end}'}                        
                        response = requests.get(url, headers=headers, stream=True)

                        if response.status_code in [206, 200]:
                            for chunk in response.iter_content(chunk_size=8192):
                                if chunk:
                                    f.write(chunk)
                                    downloaded_size += len(chunk)
                                    self.total_downloaded += len(chunk)
                                    self.current_downloaded = self.total_downloaded
                                    # Обновляем общий прогресс
                                    self.update_progress.emit(self.total_downloaded / self.total_size)
                            break
                    except Exception as e:
                        if attempt == self.max_retries - 1:
                            raise Exception(f"Не удалось загрузить сегмент файла {self.max_retries} попыток")
                        continue

        return temp_path                      
                              
    def run(self):
        try:
            self.check_existing_files()
            
            # Вычисляем общий размер файлов для загрузки
            self.total_size = sum(file_info['size'] for file_info in self.files_to_process.values())
            self.total_downloaded = 0

            if len(self.files_to_process) == 0:
               self.update_status.emit('Все файлы актуальны')
               self.update_progress.emit(1.0)  # Устанавливаем полный прогресс
               return
            
            for filename, file_info in self.files_to_process.items():
                if not self.is_downloading:
                    break

                self.update_file_name.emit(filename)
                local_path = os.path.join(self.game_path, filename)
            
                # Создаем директории если нужно
                os.makedirs(os.path.dirname(local_path), exist_ok=True)
                
                # Загружаем файлы сегментами
                temp_path = self.download_file_segmented(
                    f'http://dl.neix.ru/{filename}',
                    local_path,
                    file_info['size']
                )

                # Проверяем целостность файла
                if self.verify_checksum(temp_path, file_info['hash']):
                    if os.path.exists(local_path):
                        os.remove(local_path)
                    os.rename(temp_path, local_path)
                else:
                    self.corrupted_files.append(filename)
                    if os.path.exists(temp_path):
                        os.remove(temp_path)

            if self.is_downloading:
                status = 'Загрузка успешно завершена!' if not self.corrupted_files else 'Загрузка завершена с ошибками'
                self.update_status.emit(status)

        except Exception as e:
            self.logger.error(f"Ошибка при загрузке: {str(e)}")
            self.update_status.emit(f'Ошибка: {str(e)}')
        finally:
            self.finished.emit()

class ServerChecker(QThread):
    status_changed = pyqtSignal(bool, str)

    def __init__(self, auth_host='127.0.0.1', auth_port=3724, world_host='127.0.0.1', world_port=8085):
        super().__init__()
        self.auth_host = auth_host
        self.auth_port = auth_port
        self.world_host = world_host
        self.world_port = world_port
        self.is_running = True
        self.logger = logging.getLogger(__name__)

    def check_port(self, host: str, port: int) -> bool:
        try:
            with socket.create_connection((host, port), timeout=2):
                return True
        except (socket.timeout, socket.error):
            return False

    def run(self):
        while self.is_running:
            auth_status = self.check_port(self.auth_host, self.auth_port)
            world_status = self.check_port(self.world_host, self.world_port)

            if auth_status and world_status:
                self.status_changed.emit(True, "Оба сервера")
            elif auth_status:
                self.status_changed.emit(True, "Auth сервер")
            elif world_status:
                self.status_changed.emit(True, "World сервер")
            else:
                self.status_changed.emit(False, "Offline")

            time.sleep(5)

    def stop(self):
        self.is_running = False

class Settings(QObject):
    settingsChanged = pyqtSignal()
    
    def __init__(self):
        super().__init__()
        self._settings = {
            'autostart': False,
            'closeOnLaunch': True,
            'speedLimit': 0,
            'autoUpdate': True,
            'slideInterval': 5,
            'showNotifications': True,
            'linuxEmulator': 'wine',  # wine, lutris, proton, portproton, crossover
            'close_to_tray': True
        }
        self.load_settings()
    
    def load_settings(self):
        try:
            if os.path.exists('settings.json'):
                with open('settings.json', 'r') as f:
                    self._settings.update(json.load(f))
        except Exception as e:
            logging.error(f"Ошибка загрузки настроек: {e}")
    
    def save_settings(self):
        try:
            with open('settings.json', 'w') as f:
                json.dump(self._settings, f)
        except Exception as e:
            logging.error(f"Ошибка сохранения настроек: {e}")
    
    @pyqtProperty(bool, notify=settingsChanged)
    def autostart(self): return self._settings['autostart']
    @autostart.setter
    def autostart(self, value):
        if self._settings['autostart'] != value:
            self._settings['autostart'] = value
            self.settingsChanged.emit()
    
    @pyqtProperty(bool, notify=settingsChanged)
    def closeOnLaunch(self): 
        return self._settings['closeOnLaunch']
    @closeOnLaunch.setter
    def closeOnLaunch(self, value):
        if self._settings['closeOnLaunch'] != value:
            self._settings['closeOnLaunch'] = value
            self.settingsChanged.emit()
    
    @pyqtProperty(int, notify=settingsChanged)
    def speedLimit(self): return self._settings['speedLimit']
    @speedLimit.setter
    def speedLimit(self, value):
        if self._settings['speedLimit'] != value:
            self._settings['speedLimit'] = value
            self.settingsChanged.emit()
    
    @pyqtProperty(bool, notify=settingsChanged)
    def autoUpdate(self): return self._settings['autoUpdate']
    @autoUpdate.setter
    def autoUpdate(self, value):
        if self._settings['autoUpdate'] != value:
            self._settings['autoUpdate'] = value
            self.settingsChanged.emit()
    
    @pyqtProperty(int, notify=settingsChanged)
    def slideInterval(self): return self._settings['slideInterval']
    @slideInterval.setter
    def slideInterval(self, value):
        if self._settings['slideInterval'] != value:
            self._settings['slideInterval'] = value
            self.settingsChanged.emit()
    
    @pyqtProperty(bool, notify=settingsChanged)
    def showNotifications(self): return self._settings['showNotifications']
    @showNotifications.setter
    def showNotifications(self, value):
        if self._settings['showNotifications'] != value:
            self._settings['showNotifications'] = value
            self.settingsChanged.emit()

    @pyqtProperty(str, notify=settingsChanged)
    def linuxEmulator(self): return self._settings['linuxEmulator']
    @linuxEmulator.setter
    def linuxEmulator(self, value):
        if self._settings['linuxEmulator'] != value:
            self._settings['linuxEmulator'] = value
            self.settingsChanged.emit()

    @pyqtProperty(bool, notify=settingsChanged)
    def closeToTray(self):
        return self._settings['close_to_tray']
    
    @closeToTray.setter
    def closeToTray(self, value):
        if self._settings['close_to_tray'] != value:
            self._settings['close_to_tray'] = value
            self.settingsChanged.emit()
            self.save_settings()

class LauncherBackend(QObject):
    # Сигналы
    statusTextChanged = pyqtSignal()
    gamePathChanged = pyqtSignal()
    isDownloadingChanged = pyqtSignal()
    downloadProgressChanged = pyqtSignal()
    downloadSpeedChanged = pyqtSignal()
    currentFileNameChanged = pyqtSignal()
    currentImageChanged = pyqtSignal()
    canPlayChanged = pyqtSignal()
    serverStatusChanged = pyqtSignal()
    isServerOnlineChanged = pyqtSignal()
    versionChanged = pyqtSignal()
    notificationRequested = pyqtSignal(str, str)  # message, type
    downloadSizeInfoChanged = pyqtSignal() # новый сигнал

    def __init__(self, config_manager):
        super().__init__()
        self.logger = logging.getLogger(__name__)
        self._config_manager = config_manager
        self._download_manager = None
        self._server_checker = ServerChecker()
        self._server_checker.status_changed.connect(self._handle_server_status)
        self._server_checker.start()
        
        # Сохраняем ссылку на engine
        self.engine = None  # Будет установлено позже
        
        # Инициализация свойств
        self._game_path = config_manager.game_path or ""
        self._is_downloading = False
        self._download_progress = 0.0
        self._download_speed = ""
        self._current_file_name = ""
        self._current_image = "images/slide/1.jpg"
        self._can_play = False
        self._server_status = "⚫ Offline"
        self._is_server_online = False
        self._version = "3.3.5"
        self._status_text = "Пожалуйста, выберите папку с игрой"  # Инициализируем значение по умолчанию
        
        # Инициализация слайд-шоу
        self._slides = [
            "qml/images/slide1.jpg",
            "qml/images/slide2.jpg",
            "qml/images/slide3.jpg",
            "qml/images/slide4.jpg"
        ]
        
        # Проверяем возможность игры при старте
        self._check_can_play()

        # Подключаем сигнал к QML
        self.notificationRequested.connect(
            lambda msg, type: QMetaObject.invokeMethod(
                self.engine.rootObjects()[0],
                "showNotification",
                Q_ARG(QVariant, msg),
                Q_ARG(QVariant, type)
            )
        )

        self._settings = Settings()
        self._file_verifier = None
        self._download_size_info = ""

        # Инициализация трея
        self._tray_icon = QSystemTrayIcon()
        self._tray_icon.setIcon(QIcon("qml/images/icons/tray.png")) # Иконка для трея
        self._tray_icon.setToolTip("AzerothCraft Launcher")

        # Создаем меню для трея
        tray_menu = QMenu()
        show_action = QAction('Показать', self)
        quit_action = QAction('Выход', self)

        show_action.triggered.connect(self.show_window)
        quit_action.triggered.connect(QApplication.quit)

        tray_menu.addAction(show_action)
        tray_menu.addSeparator()
        tray_menu.addAction(quit_action)

        self._tray_icon.setContextMenu(tray_menu)
        self._tray_icon.activated.connect(self._tray_icon_activated)
        self._tray_icon.show()

    # Свойства через декораторы
    @pyqtProperty(str, notify=statusTextChanged)
    def statusText(self): return self._status_text
    @statusText.setter
    def statusText(self, value):
        if self._status_text != value:
            self._status_text = value
            self.statusTextChanged.emit()

    @pyqtProperty(str, notify=gamePathChanged)
    def gamePath(self): return self._game_path
    @gamePath.setter
    def gamePath(self, value):
        if self._game_path != value:
            self._game_path = value
            self.gamePathChanged.emit()

    @pyqtProperty(bool, notify=isDownloadingChanged)
    def isDownloading(self): return self._is_downloading
    @isDownloading.setter
    def isDownloading(self, value):
        if self._is_downloading != value:
            self._is_downloading = value
            self.isDownloadingChanged.emit()

    @pyqtProperty(float, notify=downloadProgressChanged)
    def downloadProgress(self): return self._download_progress
    @downloadProgress.setter
    def downloadProgress(self, value):
        if self._download_progress != value:
            self._download_progress = value
            self.downloadProgressChanged.emit()

    @pyqtProperty(str, notify=downloadSpeedChanged)
    def downloadSpeed(self): return self._download_speed
    @downloadSpeed.setter
    def downloadSpeed(self, value):
        if self._download_speed != value:
            self._download_speed = value
            self.downloadSpeedChanged.emit()

    @pyqtProperty(str, notify=currentFileNameChanged)
    def currentFileName(self): return self._current_file_name
    @currentFileName.setter
    def currentFileName(self, value):
        if self._current_file_name != value:
            self._current_file_name = value
            self.currentFileNameChanged.emit()

    @pyqtProperty(str, notify=currentImageChanged)
    def currentImage(self): return self._current_image
    @currentImage.setter
    def currentImage(self, value):
        if self._current_image != value:
            self._current_image = value
            self.currentImageChanged.emit()

    @pyqtProperty(bool, notify=canPlayChanged)
    def canPlay(self): return self._can_play
    @canPlay.setter
    def canPlay(self, value):
        if self._can_play != value:
            self._can_play = value
            self.canPlayChanged.emit()

    @pyqtProperty(str, notify=serverStatusChanged)
    def serverStatus(self): return self._server_status
    @serverStatus.setter
    def serverStatus(self, value):
        if self._server_status != value:
            self._server_status = value
            self.serverStatusChanged.emit()

    @pyqtProperty(bool, notify=isServerOnlineChanged)
    def isServerOnline(self): return self._is_server_online
    @isServerOnline.setter
    def isServerOnline(self, value):
        if self._is_server_online != value:
            self._is_server_online = value
            self.isServerOnlineChanged.emit()

    @pyqtProperty(str, notify=versionChanged)
    def version(self): return self._version

    @pyqtProperty(list)
    def slides(self):
        return self._slides

    @pyqtProperty(QObject, constant=True)
    def settings(self):
        return self._settings
    
    @pyqtProperty(str, notify=downloadSizeInfoChanged)
    def downloadSizeInfo(self): return self._download_size_info
    @downloadSizeInfo.setter
    def downloadSizeInfo(self, value):
        if self._download_size_info != value:
            self._download_size_info = value
            self.downloadSizeInfoChanged.emit()

    @pyqtSlot()
    def selectGamePath(self):
        try:
            folder = QFileDialog.getExistingDirectory(None, "Выберите папку с игрой")
            if folder:
                self.gamePath = folder
                self._config_manager.save_game_path(folder)
                self.statusText = f"Выбрана папка: {folder}"
                self._check_can_play()
                if not self.canPlay:
                    self.notificationRequested.emit(
                        "Игра не обнаружена. Нажмите 'Скачать клиент' для загрузки",
                        "info"
                    )
                else:
                    self.notificationRequested.emit(
                        "Папка с игрой успешно выбрана",
                        "success"
                    )
        except Exception as e:
            self._handle_error(f"Ошибка при выборе папки: {str(e)}")

    @pyqtSlot()
    def startDownload(self):
        if self.isDownloading:
            if self._download_manager:
                self._download_manager.stop()
                self._download_manager = None
            self.isDownloading = False
            self.statusText = "Загрузка остановлена"
            self.downloadProgress = 0.0
            self.downloadSpeed = ""
            self.currentFileName = ""
            return

        if not self.gamePath:
            self.statusText = "Сначала выберите папку для установки"
            return

        self.isDownloading = True
        self.statusText = "Начало загрузки..."
        self._download_manager = DownloadManager("http://you.url.com/client.json", self.gamePath)
        self._download_manager.update_progress.connect(self._handle_progress)
        self._download_manager.update_status.connect(self._handle_status)
        self._download_manager.update_file_name.connect(self._handle_filename)
        self._download_manager.update_speed.connect(self._handle_speed)
        self._download_manager.finished.connect(self._handle_download_finished)
        self._download_manager.update_size_info.connect(self._handle_size_info)
        self._download_manager.start()

    @pyqtSlot()
    def launchGame(self):
        if not self.canPlay:
            return
            
        try:
            game_exe = os.path.join(self.gamePath, "Wow.exe")
            game_process = None

            if platform.system() == 'Windows':
                game_process = subprocess.Popen([game_exe])
            else:
                emulator = self._settings.linuxEmulator
                if emulator == 'wine':
                    game_process = subprocess.Popen(['wine', game_exe])
                elif emulator == 'lutris':
                    game_process = subprocess.Popen(['lutris', 'rungame', game_exe])
                elif emulator == 'proton':
                    game_process = subprocess.Popen(['proton', 'run', game_exe])
                elif emulator == 'portproton':
                    game_process = subprocess.Popen(['portproton', 'run', game_exe])
                elif emulator == 'crossover':
                    game_process = subprocess.Popen(['crossover', game_exe])

            self.statusText = "Игра запущена"        

            # Сворачиваем в трей если включена настройка
            if self._settings.closeOnLaunch:
                self.minimizeToTray()

                # Запускаем мониторинг процесса игры в отдельном потоке
                monitor_thread = threading.Thread(
                    target=self._monitor_game_process,
                    args=(game_process,),
                    daemon=True                
                )
                monitor_thread.start()

        except Exception as e:
            self.statusText = f"Ошибка при запуске игры: {str(e)}"

    def _monitor_game_process(self, process):
        """Мониторит процесс игры и разворачивает лаунчер после завершения"""
        try:
            process.wait() # Ждем завершения процесса игры
            # разворачиваем лаунчер
            QMetaObject.invokeMethod(
                self,
                "show_window",
                Qt.QueuedConnection
            )
            if self._settings.showNotifications:
                self._tray_icon.showMessage(
                    "WoW Launcher",
                    "Игра завершена",
                    QSystemTrayIcon.Information, # Используем информационное сообщение
                    2000
                )
        except Exception as e:
            self.logger.error(f"Ошибка при мониторинге процесса игры: {str(e)}")

    def _check_can_play(self):
        if self.gamePath:
            if os.path.exists(os.path.join(self.gamePath, "Wow.exe")):
                self.canPlay = True
                self.statusText = f"Выбрана папка: {self.gamePath}"
            else:
                self.canPlay = False
                self.statusText = "Игра не обнаружена. Нажмите 'Скачать клиент' для загрузки"
        else:
            self.canPlay = False
            self.statusText = "Пожалуйста, выберите папку с игрой"

    def _handle_progress(self, progress):
        self.downloadProgress = progress

    def _handle_status(self, status):
        self.statusText = status

    def _handle_filename(self, filename):
        self.currentFileName = filename

    def _handle_speed(self, speed):
        self.downloadSpeed = speed

    def _handle_download_finished(self):
        self.isDownloading = False
        self._check_can_play()

        # Сбрасываем прогресс и скорость при завершении
        self.downloadProgress = 0.0
        self.downloadSpeed = ""
        self.currentFileName = ""
        self.downloadSizeInfo = "" # Сбрасываем информацию о размере

        if self._download_manager and self._download_manager.corrupted_files:
            corrupted = len(self._download_manager.corrupted_files)
            self.notificationRequested.emit(
                f"Загрузка завершена с ошибками. Повреждено файлов: {corrupted}",
                "error"
            )
        else:
            self.notificationRequested.emit(
                "Загрузка завершена успешно",
                "success"
            )
        
        self._download_manager = None

    def _handle_server_status(self, is_online, status):
        self.isServerOnline = is_online
        self.serverStatus = f"{'🟢' if is_online else '⚫'} {status}"

    def _handle_error(self, error_msg):
        self.logger.error(error_msg)
        self.notificationRequested.emit(error_msg, "error")

    @pyqtSlot()
    def saveSettings(self):
        self._settings.save_settings()
        # Применяем настройки
        if self._settings.autostart:
            self._setup_autostart()
        # ... другие действия при изменении настроек ...

    @pyqtSlot()
    def openGameFolder(self):
        if self.gamePath:
            if platform.system() == 'Windows':
                os.startfile(self.gamePath)
            else:
                subprocess.Popen(['xdg-open', self.gamePath])

    @pyqtSlot()
    def verifyFiles(self):
        if not self.isDownloading and self.gamePath:
            self.statusText = "Проверка файлов..."
            self._file_verifier = FileVerifier("http://you.url.com/client.json", self.gamePath)
            self._file_verifier.progress_changed.connect(self._handle_verify_progress)
            self._file_verifier.status_changed.connect(self._handle_status)
            self._file_verifier.verification_complete.connect(self._handle_verify_complete)
            self._file_verifier.start()
            self.notificationRequested.emit("Проверка файлов начата", "info")
    
    def _handle_verify_progress(self, progress):
        self.downloadProgress = progress
    
    def _handle_verify_complete(self, corrupted_files):
        if corrupted_files:
            self.statusText = f"Найдено {len(corrupted_files)} поврежденных файлов"
            self.notificationRequested.emit(
                f"Проверка завершена. Найдено {len(corrupted_files)} поврежденных файлов",
                "error"
            )
            # Спрашиваем пользователя о восстановлении
            self.repairClient(corrupted_files)
        else:
            self.statusText = "Проверка завершена. Все файлы в порядке"
            self.notificationRequested.emit(
                "Проверка завершена. Все файлы в порядке",
                "success"
            )
        self.downloadProgress = 0.0
    
    @pyqtSlot()
    def repairClient(self, files_to_repair=None):
        if not self.isDownloading and self.gamePath:
            self.statusText = "Восстановление клиента..."
            # Если список файлов не передан, проверяем все файлы
            if files_to_repair is None:
                self.verifyFiles()
                return
            
            # Запускаем загрузку только поврежденных файлов
            self.isDownloading = True
            self._download_manager = DownloadManager(
                "http://you.url.com/client.json",
                self.gamePath,
                files_to_repair
            )
            self._download_manager.update_progress.connect(self._handle_progress)
            self._download_manager.update_status.connect(self._handle_status)
            self._download_manager.update_file_name.connect(self._handle_filename)
            self._download_manager.update_speed.connect(self._handle_speed)
            self._download_manager.finished.connect(self._handle_download_finished)
            self._download_manager.start()
            self.notificationRequested.emit(
                f"Начато восстановление {len(files_to_repair)} файлов",
                "info"
            )

    @pyqtSlot()
    def checkEmulator(self):
        try:
            emulator = self._settings.linuxEmulator
            if platform.system() == 'Windows':
                self.notificationRequested.emit(
                    "Проверка эмулятора доступна только в Linux/Mac",
                    "info"
                )
                return
            
            # Проверяем наличие эмулятора
            if emulator == 'wine':
                process = subprocess.Popen(['wine', '--version'], 
                                        stdout=subprocess.PIPE, 
                                        stderr=subprocess.PIPE)
            elif emulator == 'lutris':
                process = subprocess.Popen(['lutris', '--version'], 
                                        stdout=subprocess.PIPE, 
                                        stderr=subprocess.PIPE)
            elif emulator == 'proton':
                process = subprocess.Popen(['proton', '--version'], 
                                        stdout=subprocess.PIPE, 
                                        stderr=subprocess.PIPE)
            elif emulator == 'portproton':
                process = subprocess.Popen(['portproton', '--version'], 
                                        stdout=subprocess.PIPE, 
                                        stderr=subprocess.PIPE)
            elif emulator == 'crossover':
                process = subprocess.Popen(['crossover', '--version'], 
                                        stdout=subprocess.PIPE, 
                                        stderr=subprocess.PIPE)
            
            out, err = process.communicate()
            if process.returncode == 0:
                self.notificationRequested.emit(
                    f"Эмулятор {emulator} установлен и работает корректно",
                    "success"
                )
            else:
                self.notificationRequested.emit(
                    f"Эмулятор {emulator} не найден или не работает",
                    "error"
                )
        except Exception as e:
            self.notificationRequested.emit(
                f"Ошибка при проверке эмулятора: {str(e)}",
                "error"
            )

    def _handle_size_info(self, size_info):
        self.downloadSizeInfo = size_info

    @pyqtSlot()
    def show_window(self):
        if self.engine and self.engine.rootObjects():
            window = self.engine.rootObjects()[0]
            window.show()
            window.raise_()
            window.requestActivate()

    def _tray_icon_activated(self, reason):
        if reason == QSystemTrayIcon.DoubleClick:
            self.show_window()

    @pyqtSlot()
    def minimizeToTray(self):
        if self.engine and self.engine.rootObjects():
            window = self.engine.rootObjects()[0]
            window.hide()
            if self._settings.showNotifications:
                self._tray_icon.showMessage(
                    "WoW Launcher",
                    "Лаунчер свернут в трей",
                    QSystemTrayIcon.Information, # Используем информационное сообщение
                    2000
                )        

class FileVerifier(QThread):
    progress_changed = pyqtSignal(float)
    status_changed = pyqtSignal(str)
    verification_complete = pyqtSignal(list)  # список поврежденных файлов
    
    def __init__(self, manifest_url: str, game_path: str):
        super().__init__()
        self.manifest_url = manifest_url
        self.game_path = game_path
        self.is_running = True
        self.logger = logging.getLogger(__name__)
    
    def stop(self):
        self.is_running = False
    
    def run(self):
        try:
            self.status_changed.emit("Загрузка манифеста...")
            response = requests.get(self.manifest_url)
            response.raise_for_status()
            manifest = response.json()['files']
            
            corrupted_files = []
            total_files = len(manifest)
            checked_files = 0
            
            for filename, file_info in manifest.items():
                if not self.is_running:
                    break
                    
                local_path = os.path.join(self.game_path, filename)
                self.status_changed.emit(f"Проверка: {filename}")
                
                if not os.path.exists(local_path):
                    corrupted_files.append(filename)
                else:
                    # Проверяем размер
                    if os.path.getsize(local_path) != file_info['size']:
                        corrupted_files.append(filename)
                    else:
                        # Проверяем хеш
                        sha256_hash = hashlib.sha256()
                        with open(local_path, "rb") as f:
                            for byte_block in iter(lambda: f.read(4096), b""):
                                if not self.is_running:
                                    return
                                sha256_hash.update(byte_block)
                        
                        if sha256_hash.hexdigest() != file_info['hash']:
                            corrupted_files.append(filename)
                
                checked_files += 1
                self.progress_changed.emit(checked_files / total_files)
            
            if self.is_running:
                self.verification_complete.emit(corrupted_files)
                
        except Exception as e:
            self.logger.error(f"Ошибка при проверке файлов: {str(e)}")
            self.status_changed.emit(f"Ошибка: {str(e)}")

if __name__ == '__main__':
    app = QApplication(sys.argv)
    
    # Добавляем поддержку QtGraphicalEffects
    import os
    os.environ['QT_QUICK_CONTROLS_STYLE'] = 'Material'
    os.environ['QT_QUICK_CONTROLS_MATERIAL_VARIANT'] = 'Dense'
    
    # Устанавливаем программный рендеринг для лучшей совместимости
    from PyQt5.QtQuick import QQuickWindow
    QQuickWindow.setSceneGraphBackend('software')
    
    # Регистрируем Settings для QML
    from PyQt5.QtQml import qmlRegisterType
    qmlRegisterType(Settings, 'Settings', 1, 0, 'Settings')
    
    engine = QQmlApplicationEngine()
    
    current_dir = os.path.dirname(os.path.abspath(__file__))
    engine.addImportPath(current_dir)
    
    config_manager = ConfigManager()
    backend = LauncherBackend(config_manager)
    backend.engine = engine  # Устанавливаем ссылку на engine
    engine.rootContext().setContextProperty("launcher", backend)
    
    qml_file = os.path.join(current_dir, 'main.qml')
    engine.load(QUrl.fromLocalFile(qml_file))
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec_())
