package hm.edu.backend.services;

import hm.edu.backend.model.MenuItem;
import hm.edu.backend.repositories.MenuItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class MenuItemServiceImpl implements MenuItemService{

    @Autowired
    private MenuItemRepository menuItemRepository;

    /**
     * Speichert ein neues MenuItem.
     * @param item neues MenuItem
     */
    @Override
    public void saveMenuItem(MenuItem item) {
        menuItemRepository.save(item);
    }

    /**
     * Findet ein MenuItem per ID.
     * @param id des MenuItems.
     * @return MenuItem mit der ID.
     * @throws ResponseStatusException  404, wenn das MenuItem nicht existiert
     */
    @Override
    public MenuItem getMenuItemById(long id) throws ResponseStatusException {
        return menuItemRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Menu Item does not exist"));
    }

    /**
     * Löscht ein MenuItem mit der ID.
     * @param id ID des zu löschenden MenuItems.
     */
    @Override
    public void deleteMenuItemById(long id) {
        menuItemRepository.deleteById(id);
    }

    /**
     * Aktualisiert ein MenuItem in der Datenbank, falls vorhanden.
     * Altes MenuItem wird archiviert und neues mit erhöhter Version gespeichert
     * @param item MenuItem-Objekt mit neuen Daten.
     */
    @Override
    public void updateMenuItem(MenuItem item) {
        try {
            MenuItem existingItem = getMenuItemById(item.getId());
            MenuItem newItem = new MenuItem(item.getName(), item.getDescription(), item.getPrice(), existingItem.getVersion() + 1, false);
            existingItem.setArchived(true);
            menuItemRepository.save(existingItem);
            menuItemRepository.save(newItem);
        } catch (RuntimeException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Menu Item does not exist");
        }
    }

    /**
     * Liefert alle MenuItems in der Datenbank.
     * @return alle MenuItems.
     */
    @Override
    public List<MenuItem> getAllMenuItems() {
        return menuItemRepository.findAll();
    }

    /**
     * Liefert eine gefilterte Liste aller MenuItems nach Version.
     * @param version Versionsnummer zum Filtern
     * @return alle MenuItems, die dem Filter entsprechen
     */
    @Override
    public List<MenuItem> getAllMenuItemsByVersion(int version) {
        return menuItemRepository.findByVersion(version);
    }

    /**
     * Liefert eine gefilterte Liste aller MenuItems nach Archiv-Status.
     * @return alle MenuItems, die dem Filter entsprechen
     */
    @Override
    public List<MenuItem> getAllMenuItemsByArchived(boolean archived) {
        return menuItemRepository.findByArchived(archived);
    }

    /**
     * Archiviert ein MenuItem mit der gegebenen ID.
     * @param id ID des zu archivierenden MenuItems.
     */
    @Override
    public void archiveMenuItem(Long id) {
        MenuItem item = this.getMenuItemById(id);
        item.setArchived(true);
        menuItemRepository.save(item);
    }

    /**
     * Archiviert ein MenuItem in einer BarOrder, indem ein neues archiviertes MenuItem erstellt wird.
     * @param id ID des zu archivierenden MenuItems.
     * @return das neu erstellte archivierte MenuItem.
     */
    @Override
    public MenuItem archiveMenuItemInBarOrder(Long id) {
        MenuItem item = this.getMenuItemById(id);
        MenuItem archivedItem = new MenuItem(
                item.getName(),
                item.getDescription(),
                item.getPrice(),
                item.getVersion(),
                true
        );
        menuItemRepository.save(archivedItem);
        return archivedItem;
    }

}
