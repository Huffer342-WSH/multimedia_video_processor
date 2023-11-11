class RuntimeStylesheets(QMainWindow, QtStyleTools):
    
    def __init__(self):
        super().__init__()
        self.main = QUiLoader().load('main_window.ui', self)
        
        self.show_dock_theme(self.main)
