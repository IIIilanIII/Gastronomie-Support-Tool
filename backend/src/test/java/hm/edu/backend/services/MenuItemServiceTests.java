package hm.edu.backend.services;

import hm.edu.backend.model.MenuItem;
import hm.edu.backend.repositories.MenuItemRepository;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class MenuItemServiceTests {
    @InjectMocks
    MenuItemServiceImpl menuItemServiceImpl;
    @Mock
    MenuItemRepository menuItemRepository;

    /**
     * getAllMenuItems: keine MenuItems existieren
     * Expects: leere Liste
     */
    @Test
    public void testAllItems1() {
        // Mock Vorbereitung: keine MenuItems existieren
        when(menuItemRepository.findAll()).thenReturn(List.of());

        // Ausfuehrung und Test der Antwort
        List<MenuItem> result = menuItemServiceImpl.getAllMenuItems();

        // Call Verifikation: findAll wurde aufgerufen
        verify(menuItemRepository).findAll();

        // Ergebnis Test
        assert result != null;
        assertEquals(0, result.size());
    }

    /**
     * getAllMenuItems: 4 MenuItems existieren
     * Expects: Liste mit 4 MenuItems
     */
    @Test
    public void testAllItems2() {
        // Mock Vorbereitung: 4 MenuItems existieren
        List<MenuItem> mockList = List.of(
                new MenuItem("name1", "description", 1, 1, false),
                new MenuItem("name2", "description", 1, 1, false),
                new MenuItem("name3", "description", 1, 1, false),
                new MenuItem("name4", "description", 1, 1, false)
        );
        when(menuItemRepository.findAll()).thenReturn(mockList);

        // Ausfuehrung und Test der Antwort
        List<MenuItem> result = menuItemServiceImpl.getAllMenuItems();

        // Call Verifikation: findAll wurde aufgerufen
        verify(menuItemRepository).findAll();

        // Ergebnis Test
        assert result != null;
        assertEquals(4, result.size());
        assertEquals("name1", result.get(0).getName());
        assertEquals("name2", result.get(1).getName());
        assertEquals("name3", result.get(2).getName());
        assertEquals("name4", result.get(3).getName());
    }

    /**
     * saveMenuItem: neues MenuItem wird gespeichert
     * Expects: MenuItem erfolgreich gespeichert
     */
    @Test
    void testNewItem1() {
        // Mock Vorbereitung: neues MenuItem
        MenuItem newItem = new MenuItem("name", "description", 1, 1, false);
        when(menuItemRepository.save(newItem)).thenReturn(newItem);

        // Ausfuehrung
        menuItemServiceImpl.saveMenuItem(newItem);

        // Call Verifikation: save wurde aufgerufen
        verify(menuItemRepository).save(newItem);
    }

    /**
     * getMenuItemById: MenuItem existiert
     * Expects: MenuItem mit korrekten Daten
     */
    @Test
    void testGetItem1() {
        // Mock Vorbereitung: MenuItem existiert
        MenuItem newItem = new MenuItem(1L, "name", "description", 1, 1, false);
        when(menuItemRepository.findById(1L)).thenReturn(Optional.of(newItem));

        // Ausfuehrung und Test der Antwort
        MenuItem result = menuItemServiceImpl.getMenuItemById(1L);

        // Call Verifikation: findById wurde aufgerufen
        verify(menuItemRepository).findById(1L);

        // Ergebnis Test
        assert result != null;
        assertEquals("name", result.getName());
        assertEquals("description", result.getDescription());
    }

    /**
     * getMenuItemById: MenuItem existiert nicht
     * Expects: RuntimeException
     */
    @Test
    void testGetItem2() {
        // Mock Vorbereitung: MenuItem existiert nicht
        when(menuItemRepository.findById(1L)).thenReturn(Optional.empty());

        // Ausfuehrung und Test der Antwort
        Assertions.assertThrows(RuntimeException.class, () -> menuItemServiceImpl.getMenuItemById(1L));
    }

    /**
     * updateMenuItem: MenuItem existiert
     * Expects: altes MenuItem archiviert, neues MenuItem mit Version 2 gespeichert
     */
    @Test
    @SuppressWarnings("ConstantConditions")
    void testUpdateItem1() {
        // Mock Vorbereitung: MenuItem existiert
        MenuItem originalItem = new MenuItem(1L, "name1", "description", 1, 1, false);
        MenuItem originalItemArchived = new MenuItem(1L, "name1", "description", 1, 1, true);
        MenuItem updatedItemExpect = new MenuItem(2L, "name2", "description", 1, 2, false);
        MenuItem updatedItemInsert = new MenuItem(1L, "name2", "description", 1, 1, false);
        when(menuItemRepository.findById(1L)).thenReturn(Optional.of(originalItem));
        when(menuItemRepository.save(any(MenuItem.class)))
                .thenReturn(originalItemArchived)
                .thenReturn(updatedItemExpect);

        // Ausfuehrung
        menuItemServiceImpl.updateMenuItem(updatedItemInsert);

        // Call Verifikation: save wurde zweimal aufgerufen
        verify(menuItemRepository).save(refEq(originalItemArchived));
        verify(menuItemRepository).save(refEq(updatedItemExpect, "id"));
    }

    /**
     * updateMenuItem: MenuItem existiert nicht
     * Expects: ResponseStatusException
     */
    @Test
    void testUpdateItem2() {
        // Mock Vorbereitung: MenuItem existiert nicht
        MenuItem updatedItem = new MenuItem(1L, "name2", "description", 1, 1, false);
        when(menuItemRepository.findById(1L)).thenReturn(Optional.empty());

        // Ausfuehrung und Test der Antwort
        Assertions.assertThrows(ResponseStatusException.class, () -> menuItemServiceImpl.updateMenuItem(updatedItem));

        // Call Verifikation: findById wurde aufgerufen, save nicht
        verify(menuItemRepository).findById(1L);
        verify(menuItemRepository, never()).save(updatedItem);
    }

    /**
     * deleteMenuItemById: MenuItem wird geloescht
     * Expects: deleteById aufgerufen
     */
    @Test
    void testDeleteItem() {
        // Ausfuehrung
        menuItemServiceImpl.deleteMenuItemById(1L);

        // Call Verifikation: deleteById wurde aufgerufen
        verify(menuItemRepository).deleteById(1L);
    }

    /**
     * getAllMenuItemsByVersion: 2 MenuItems mit Version 2 existieren
     * Expects: Liste mit 2 MenuItems
     */
    @Test
    void testGetAllMenuItemsByVersion_found() {
        // Mock Vorbereitung: 2 MenuItems mit Version 2 existieren
        MenuItem item1 = new MenuItem("A", "Desc", 1.0, 2, false);
        MenuItem item2 = new MenuItem("B", "Desc", 2.0, 2, false);
        when(menuItemRepository.findByVersion(2)).thenReturn(List.of(item1, item2));

        // Ausfuehrung und Test der Antwort
        List<MenuItem> result = menuItemServiceImpl.getAllMenuItemsByVersion(2);

        // Call Verifikation: findByVersion wurde aufgerufen
        verify(menuItemRepository).findByVersion(2);

        // Ergebnis Test
        assertEquals(2, result.size());
        assertEquals(2, result.get(0).getVersion());
        assertEquals(2, result.get(1).getVersion());
    }

    /**
     * getAllMenuItemsByVersion: keine MenuItems mit Version 99 existieren
     * Expects: leere Liste
     */
    @Test
    void testGetAllMenuItemsByVersion_noneFound() {
        // Mock Vorbereitung: keine MenuItems mit Version 99 existieren
        when(menuItemRepository.findByVersion(99)).thenReturn(List.of());

        // Ausfuehrung und Test der Antwort
        List<MenuItem> result = menuItemServiceImpl.getAllMenuItemsByVersion(99);

        // Call Verifikation: findByVersion wurde aufgerufen
        verify(menuItemRepository).findByVersion(99);

        // Ergebnis Test
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    /**
     * getAllMenuItemsByArchived: 2 archivierte MenuItems existieren
     * Expects: Liste mit 2 archivierten MenuItems
     */
    @Test
    void testGetAllMenuItemsByArchived_found() {
        // Mock Vorbereitung: 2 archivierte MenuItems existieren
        MenuItem item1 = new MenuItem("A", "Desc", 1.0, 1, true);
        MenuItem item2 = new MenuItem("B", "Desc", 2.0, 1, true);
        when(menuItemRepository.findByArchived(true)).thenReturn(List.of(item1, item2));

        // Ausfuehrung und Test der Antwort
        List<MenuItem> result = menuItemServiceImpl.getAllMenuItemsByArchived(true);

        // Call Verifikation: findByArchived wurde aufgerufen
        verify(menuItemRepository).findByArchived(true);

        // Ergebnis Test
        assertEquals(2, result.size());
        assertTrue(result.get(0).isArchived());
        assertTrue(result.get(1).isArchived());
    }

    /**
     * getAllMenuItemsByArchived: keine nicht-archivierten MenuItems existieren
     * Expects: leere Liste
     */
    @Test
    void testGetAllMenuItemsByArchived_noneFound() {
        // Mock Vorbereitung: keine nicht-archivierten MenuItems existieren
        when(menuItemRepository.findByArchived(false)).thenReturn(List.of());

        // Ausfuehrung und Test der Antwort
        List<MenuItem> result = menuItemServiceImpl.getAllMenuItemsByArchived(false);

        // Call Verifikation: findByArchived wurde aufgerufen
        verify(menuItemRepository).findByArchived(false);

        // Ergebnis Test
        assertNotNull(result);
        assertTrue(result.isEmpty());
    }

    /**
     * archiveMenuItem: MenuItem existiert
     * Expects: MenuItem erfolgreich archiviert
     */
    @Test
    void testArchiveMenuItemValid() {
        // Mock Vorbereitung: MenuItem existiert
        Long id = 1L;
        MenuItem existing = new MenuItem(id, "Item", "Desc", 2.5, 1, false);
        when(menuItemRepository.findById(id)).thenReturn(Optional.of(existing));

        // Ausfuehrung
        menuItemServiceImpl.archiveMenuItem(id);

        // Call Verifikation: findById und save wurden aufgerufen
        verify(menuItemRepository).findById(id);
        verify(menuItemRepository).save(existing);

        // Ergebnis Test
        assertTrue(existing.isArchived());
    }

    /**
     * archiveMenuItem: MenuItem existiert nicht
     * Expects: ResponseStatusException
     */
    @Test
    void testArchiveMenuItemNotFound() {
        // Mock Vorbereitung: MenuItem existiert nicht
        Long id = 99L;
        when(menuItemRepository.findById(id)).thenReturn(Optional.empty());

        // Ausfuehrung und Test der Antwort
        assertThrows(ResponseStatusException.class, () -> menuItemServiceImpl.archiveMenuItem(id));

        // Call Verifikation: save wurde nicht aufgerufen
        verify(menuItemRepository, never()).save(any(MenuItem.class));
    }

    /**
     * archiveMenuItemInBarOrder: MenuItem existiert
     * Expects: neues archiviertes MenuItem erstellt, Original unveraendert
     */
    @Test
    void testArchiveMenuItemInBarOrderValid() {
        // Mock Vorbereitung: MenuItem existiert
        Long id = 1L;
        MenuItem existing = new MenuItem(id, "Item", "Desc", 2.5, 1, false);
        when(menuItemRepository.findById(id)).thenReturn(Optional.of(existing));

        // Ausfuehrung
        MenuItem archivedItem = menuItemServiceImpl.archiveMenuItemInBarOrder(id);

        // Call Verifikation: findById und save wurden aufgerufen
        verify(menuItemRepository).findById(id);
        verify(menuItemRepository).save(archivedItem);

        // Ergebnis Test
        assertFalse(existing.isArchived());
        assertNotNull(archivedItem);
        assertEquals("Item", archivedItem.getName());
        assertEquals("Desc", archivedItem.getDescription());
        assertEquals(2.5, archivedItem.getPrice());
        assertEquals(1, archivedItem.getVersion());
        assertTrue(archivedItem.isArchived());
    }

    /**
     * archiveMenuItemInBarOrder: MenuItem existiert nicht
     * Expects: ResponseStatusException
     */
    @Test
    void testArchiveMenuItemInBarOrderNotFound() {
        // Mock Vorbereitung: MenuItem existiert nicht
        Long id = 99L;
        when(menuItemRepository.findById(id)).thenReturn(Optional.empty());

        // Ausfuehrung und Test der Antwort
        assertThrows(ResponseStatusException.class, () -> menuItemServiceImpl.archiveMenuItemInBarOrder(id));

        // Call Verifikation: save wurde nicht aufgerufen
        verify(menuItemRepository, never()).save(any(MenuItem.class));
    }
}