import unicodedata
from functools import lru_cache

from PySide6.QtCore import QSortFilterProxyModel, Property, Signal, Slot


# El buscador pide el texto de cada canción en cada tecla: así se normaliza una sola vez.
# shortcut: con más de 16384 canciones la caché se recicla y vuelve a costar como antes;
# entonces conviene guardar el texto normalizado en el propio Track.
@lru_cache(maxsize=16384)
def normalize(text: str) -> str:
    """Minúsculas y sin acentos, para buscar "cancion" y encontrar "Canción"."""
    return "".join(c for c in unicodedata.normalize("NFD", text.casefold())
                   if unicodedata.category(c) != "Mn")


class SearchFilterModel(QSortFilterProxyModel):
    """Filtra un modelo por el texto de su rol "search".
    Todas las palabras escritas tienen que aparecer (en cualquier orden)."""

    filterTextChanged = Signal()

    def __init__(self, source, parent=None):
        super().__init__(parent)
        self._words: list[str] = []
        self._text = ""
        self.setSourceModel(source)
        self._role = next(role for role, name in source.roleNames().items() if bytes(name) == b"search")

    def _get_text(self):
        return self._text

    def _set_text(self, text):
        if text == self._text:
            return
        self._text = text
        self._words = normalize(text).split()
        self.invalidateFilter()
        self.filterTextChanged.emit()

    filterText = Property(str, _get_text, _set_text, notify=filterTextChanged)

    def filterAcceptsRow(self, source_row, source_parent):
        if not self._words:
            return True
        index = self.sourceModel().index(source_row, 0, source_parent)
        haystack = self.sourceModel().data(index, self._role) or ""
        return all(word in haystack for word in self._words)

    @Slot(int, result=int)
    def proxyRow(self, source_row: int) -> int:
        """Fila visible de un elemento del modelo original (-1 si está filtrado)."""
        return self.mapFromSource(self.sourceModel().index(source_row, 0)).row()
