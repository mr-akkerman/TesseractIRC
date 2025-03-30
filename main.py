#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import logging
from logging.handlers import RotatingFileHandler
from typing import Optional, Dict

from PySide6.QtCore import QObject, Signal, Property, QUrl, QDir
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine, QmlElement
from PySide6.QtQuickControls2 import QQuickStyle

# Add project directory to import path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Import application controller
from irc_client.controller import ApplicationController

# Single instance of application controller
controller = None

# Configure logging
logger = logging.getLogger("main")
logger.setLevel(logging.INFO)

# First remove all existing handlers to avoid duplication
for handler in logger.handlers[:]:
    logger.removeHandler(handler)

# File logging
file_handler = RotatingFileHandler("irc_client.log", maxBytes=1024*1024, backupCount=3)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
logger.addHandler(file_handler)

# Configure root logger
root_logger = logging.getLogger()
root_logger.setLevel(logging.INFO)
for handler in root_logger.handlers[:]:
    root_logger.removeHandler(handler)

def main():
    """Main application function"""
    logger.info("Application starting")
    
    # Create application
    app = QGuiApplication(sys.argv)
    app.setApplicationName("TesseractIRC")
    app.setOrganizationName("TesseractIRC")
    app.setOrganizationDomain("tesseractirc.io")
    
    # Set style
    QQuickStyle.setStyle("Basic")
    
    # Get base paths
    base_dir = os.path.dirname(os.path.abspath(__file__))
    qml_dir = os.path.join(base_dir, "irc_client", "ui", "qml")
    main_qml = os.path.join(qml_dir, "Main.qml")
    
    # Check if files exist
    if not os.path.isfile(main_qml):
        logger.error(f"QML file not found: {main_qml}")
        return -1
    
    # Create application controller
    global controller
    controller = ApplicationController()
    
    # Create QML engine
    engine = QQmlApplicationEngine()
    
    # Add QML files folder to import path
    engine.addImportPath(qml_dir)
    
    # Export controller to QML
    engine.rootContext().setContextProperty("appController", controller)
    
    # Create debug element and export it to QML
    import time
    test_obj = {"time": str(time.time()), "value": "test"}
    engine.rootContext().setContextProperty("testObj", test_obj)
    
    # Load main QML file
    engine.load(QUrl.fromLocalFile(main_qml))
    
    # Check if QML loaded
    if not engine.rootObjects():
        logger.error("Failed to load QML file")
        return -1
    
    # Start event loop
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
