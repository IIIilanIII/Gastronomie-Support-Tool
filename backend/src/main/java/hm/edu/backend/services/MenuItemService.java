package hm.edu.backend.services;
import hm.edu.backend.model.MenuItem;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

public interface MenuItemService {
    /**
     * Speichert ein neues MenuItem.
     * @param item neues MenuItem
     */
    void saveMenuItem(MenuItem item);

    /**
     * Findet ein MenuItem per ID.
     * @param id des MenuItems.
     * @return MenuItem mit der ID.
     * @throws ResponseStatusException 404, wenn das MenuItem nicht existiert
     */
    MenuItem getMenuItemById(long id) throws ResponseStatusException;

    /**
     * Löscht ein MenuItem mit der ID.
     * @param id ID des zu löschenden MenuItems.
     */
    void deleteMenuItemById(long id);

    /**
     * Aktualisiert ein MenuItem in der Datenbank, falls vorhanden,
     * sonst wird das MenuItem gespeichert.
     * @param item MenuItem-Objekt mit neuen Daten.
     */
    void updateMenuItem(MenuItem item);

    /**
     * Liefert alle MenuItems in der Datenbank.
     * @return alle MenuItems.
     */
    List<MenuItem> getAllMenuItems();

    /**
     * Liefert eine gefilterte Liste aller MenuItems nach Version.
     * @param version Versionsnummer zum Filtern
     * @return alle MenuItems, die dem Filter entsprechen
     */
    List<MenuItem> getAllMenuItemsByVersion(int version);

    /**
     * Liefert eine gefilterte Liste aller MenuItems nach Archiv-Status.
     * @return alle MenuItems, die dem Filter entsprechen
     */
    List<MenuItem> getAllMenuItemsByArchived(boolean archived);

    /**
     * Archiviert ein MenuItem mit der gegebenen ID.
     * @param id ID des zu archivierenden MenuItems.
     */
    void archiveMenuItem(Long id);

    /**
     * Archiviert ein MenuItem in einer BarOrder, indem ein neues archiviertes MenuItem erstellt wird.
     * @param id ID des zu archivierenden MenuItems.
     * @return das neu erstellte archivierte MenuItem.
     */
    MenuItem archiveMenuItemInBarOrder(Long id);
}
