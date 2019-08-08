# -*- coding: utf-8 -*-
"""
Sharing Items

This module allows you to share items, to import files and to open URLs.
"""

from rubicon.objc import ObjCClass
from UIKit import UIApplication as __UIApplication__
import pyto
import mainthread
import threading
from typing import List
__PySharingHelper__ = pyto.PySharingHelper
NSURL = ObjCClass("NSURL")

def share_items(items: object):
    """
    Opens a share sheet with given items.
    
    :param items: Items to be shared with the sheet.
    """
    
    __PySharingHelper__.share(items)

if __host__ is not widget:
    
    def quick_look(path: str):
        """
        Previews given file.
        
        This function doesn't block the current thread. You can call this function multiple times and the file path will be appended to the current Preview controller. Thread safe.
        
        :param path: Path to preview.
        """

        try:
            pyto.QuickLookHelper.previewFile(path, script=threading.current_thread().script_path)
        except:
            pyto.QuickLookHelper.previewFile(path, script=None)

# MARK: - File picker

class FilePicker:
    """
    A class representing a file picker. Presents an ``UIDocumentPickerViewController``\ .
    
    A class representing a file picker.
    
    Example:
    
    .. highlight:: python
    .. code-block:: python

        filePicker = sharing.FilePicker()
        filePicker.file_types = ["public.data"]
        filePicker.allows_multiple_selection = True

        def files_picked() -> None:
            files = sharing.picked_files()
            sharing.share_items(files)

        filePicker.completion = files_picked
        sharing.pick_documents(filePicker)
    """

    file_types = []
    """
    Document types that can be opened.
    """

    allows_multiple_selection = False
    """
    Allow multiple selection or not.
    """

    completion = None
    """
    The code to execute when files where picked.
    """

    urls = []
    """
    Picked URLs.
    """

    def __objcFilePicker__(self):
        filePicker = pyto.FilePicker.new()
        filePicker.fileTypes = self.fileTypes
        filePicker.allowsMultipleSelection = self.allowsMultipleSelection
        filePicker.completion = self.completion

        return filePicker

    @staticmethod
    def new():
        return __FilePicker__()

def pick_documents(filePicker: FilePicker):
    """
    Pick documents with given parameters as a ``FilePicker``.

    :param filePicker: The parameters of the file picker to be presented.
    """

    script_path = None
    try:
        script_path = threading.current_thread().script_path
    except:
        pass

    __PySharingHelper__.presentFilePicker(filePicker.__objcFilePicker__(), scriptPath=script_path)

def picked_files() -> List[str]:
    """
    Returns paths of files picked with ``pickDocumentsWithFilePicker``.
    """

    urls = pyto.FilePicker.urls
    if len(urls) == 0:
        return []
    else:
        py_urls = []
        for url in urls:
            py_urls.append(str(url.path))
        return py_urls

# MARK: - URLs

def open_url(url: str):
    """
    Opens the given URL.
    
    :param url: URL to open. Can be a String or an Objective-C ``NSURL``.
    """

    __url__ = None

    def __openURL__() -> None:
        __UIApplication__.sharedApplication.openURL(__url__)

    if (type(url) is str):
        __url__ = NSURL.URLWithString(url)
        mainthread.run_sync(__openURL__)
    elif (__PySharingHelper__.isURL(url)):
        __url__ = url
        mainthread.run_sync(__openURL__)
    else:
        raise ValueError('url musts be a String or an Objective-C ``NSURL``.')

