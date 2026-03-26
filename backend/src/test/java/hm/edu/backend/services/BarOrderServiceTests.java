package hm.edu.backend.services;

import hm.edu.backend.model.BarOrder;
import hm.edu.backend.model.BarOrderItem;
import hm.edu.backend.model.BarTable;
import hm.edu.backend.model.MenuItem;
import hm.edu.backend.repositories.BarOrderRepository;
import hm.edu.backend.repositories.MenuItemRepository;
import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;
import java.util.stream.IntStream;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
public class BarOrderServiceTests {
    @InjectMocks
    BarOrderServiceImpl barOrderServiceImpl;
    @Mock
    MenuItemServiceImpl menuItemServiceImpl;
    @Mock
    BarOrderRepository barOrderRepository;
    @Mock
    MenuItemRepository menuItemRepository;

    // HILFSMETHODEN
    /** BarTable mit gegebener ID erstellen */
    static BarTable createTable(long id) {
        return new BarTable(id);
    }

    /** BarOrderItems fuer gegebene BarOrder erstellen
     *  erstellt n BarOrderItems mit MenuItems der IDs 1 bis n
     * @param order
     * @param n
     * @return
     */
    static List<BarOrderItem> createItems(BarOrder order, int n) {
        return IntStream.rangeClosed(1, n).mapToObj(i -> {
            MenuItem item = new MenuItem(i, "Item " + i, "Desc " + i, i, i, false);
            return new BarOrderItem(order, item, i);
        }).toList();
    }
    /** BarOrders mit Items erstellen
     *  erstellt n BarOrders mit IDs 1 bis n, jeweils mit BarTable der gleichen ID
     *  und mit i*2 BarOrderItems fuer BarOrder mit ID i
     * @param n
     * @return
     */
    static List<BarOrder> createOrders(int n) {
        return IntStream.rangeClosed(1, n).mapToObj(i -> {
            BarOrder order = new BarOrder(i, createTable(i), List.of());
            List<BarOrderItem> items = createItems(order, i*2);
            order.setItems(items);
            return order;
        }).toList();
    }

    /**
     * getAllBarOrders: keine BarOrders existieren
     * Expects: leere Liste
     */
    @Test
    public void testAllItems1() {
        // Mock Vorbereitung: keine BarOrders existieren
        when(barOrderRepository.findAll()).thenReturn(List.of());

        // Ausfuehrung und Test der Antwort
        List<BarOrder> result = barOrderServiceImpl.getAllBarOrders();

        // Call Verifikation: findAll wurde aufgerufen
        verify(barOrderRepository).findAll();

        // Ergebnis Test
        assert result != null;
        assertEquals(0, result.size());
    }

    /**
     * getAllBarOrders: 4 BarOrders existieren
     * Expects: Liste mit 4 BarOrders
     */
    @Test
    public void testAllItems2() {
        // Mock Vorbereitung: 4 BarOrders existieren
        List<BarOrder> mockList = createOrders(4);
        when(barOrderRepository.findAll()).thenReturn(mockList);

        // Ausfuehrung und Test der Antwort
        List<BarOrder> result = barOrderServiceImpl.getAllBarOrders();

        // Call Verifikation: findAll wurde aufgerufen
        verify(barOrderRepository).findAll();

        // Ergebnis Test
        assert result != null;
        assertEquals(4, result.size());
    }

    /**
     * saveBarOrder: neue BarOrder mit Items wird gespeichert
     * Expects: BarOrder erfolgreich gespeichert
     */
    @Test
    void testNewItem1() {
        // Mock Vorbereitung: BarOrder und MenuItems existieren
        BarOrder newOrder = createOrders(1).get(0);
        for (BarOrderItem barOrderItem : newOrder.getItems()) {
            when(menuItemServiceImpl.getMenuItemById(barOrderItem.getMenuItem().getId())).thenReturn(barOrderItem.getMenuItem());
        }
        when(barOrderRepository.save(newOrder)).thenReturn(newOrder);

        // Ausfuehrung
        barOrderServiceImpl.saveBarOrder(newOrder);

        // Call Verifikation: save wurde aufgerufen
        verify(barOrderRepository).save(newOrder);
    }

    /**
     * getBarOrderById: BarOrder existiert
     * Expects: BarOrder mit korrekten Daten
     */
    @Test
    void testGetItem1() {
        // Mock Vorbereitung: BarOrder existiert
        BarOrder newOrder = createOrders(1).get(0);
        when(barOrderRepository.findById(6L)).thenReturn(Optional.of(newOrder));

        // Ausfuehrung und Test der Antwort
        BarOrder result = barOrderServiceImpl.getBarOrderById(6L);

        // Call Verifikation: findById wurde aufgerufen
        verify(barOrderRepository).findById(6L);

        // Ergebnis Test
        assert result != null;
        assertEquals(newOrder.getId(), result.getId());
        assertEquals(newOrder.getBarTable(), result.getBarTable());
        assertEquals(newOrder.getItems(), result.getItems());
    }

    /**
     * getBarOrderById: Service wirft Exception
     * Expects: RuntimeException
     */
    @Test
    void testGetItem2() {
        // Mock Vorbereitung: Service wirft Exception
        when(barOrderRepository.findById(1L)).thenThrow(RuntimeException.class);

        // Ausfuehrung und Test der Antwort
        Assertions.assertThrows(RuntimeException.class, () -> barOrderServiceImpl.getBarOrderById(1L));
    }

    /**
     * updateBarOrder: BarOrder existiert
     * Expects: BarOrder erfolgreich aktualisiert
     */
    @Test
    void testUpdateItem1() {
        // Mock Vorbereitung: BarOrder existiert
        BarOrder originalOrder = createOrders(1).get(0);
        BarOrder updatedOrder = createOrders(2).get(1);
        updatedOrder.setId(1L);
        when(barOrderRepository.findById(1L)).thenReturn(Optional.of(originalOrder));
        when(barOrderRepository.save(updatedOrder)).thenReturn(updatedOrder);

        // Ausfuehrung
        barOrderServiceImpl.updateBarOrder(updatedOrder);

        // Call Verifikation: findById und save wurden aufgerufen
        verify(barOrderRepository).findById(1L);
        verify(barOrderRepository).save(updatedOrder);
    }

    /**
     * updateBarOrder: BarOrder existiert nicht
     * Expects: ResponseStatusException
     */
    @Test
    void testUpdateItem2() {
        // Mock Vorbereitung: BarOrder existiert nicht
        BarOrder updatedOrder = createOrders(1).get(0);
        when(barOrderRepository.findById(1L)).thenReturn(Optional.empty());

        // Ausfuehrung und Test der Antwort
        Assertions.assertThrows(ResponseStatusException.class, () -> barOrderServiceImpl.updateBarOrder(updatedOrder));

        // Call Verifikation: findById wurde aufgerufen, save nicht
        verify(barOrderRepository).findById(1L);
        verify(barOrderRepository, never()).save(updatedOrder);
    }

    /**
     * deleteBarOrderById: BarOrder wird geloescht
     * Expects: deleteById aufgerufen
     */
    @Test
    void testDeleteItem() {
        // Ausfuehrung
        barOrderServiceImpl.deleteBarOrderById(1L);

        // Call Verifikation: deleteById wurde aufgerufen
        verify(barOrderRepository).deleteById(1L);
    }

    /**
     * archiveBarOrder: BarOrder und Items werden archiviert
     * Expects: BarOrder mit archivierten Items gespeichert
     */
    @Test
    void testArchiveBarOrder() throws Exception {
        // Mock Vorbereitung: BarOrder mit MenuItem existiert
        BarOrder originalOrder = new BarOrder(1L, createTable(1L), List.of());
        MenuItem menuItem = new MenuItem(1L, "Item 1", "Desc 1", 10.0, 5, false);
        BarOrderItem barOrderItem = new BarOrderItem(originalOrder, menuItem, 2);
        originalOrder.setItems(List.of(barOrderItem));
        when(barOrderRepository.findById(1L)).thenReturn(Optional.of(originalOrder));
        MenuItem archivedMenuItem = new MenuItem(1L, "Item 1", "Desc 1", 10.0, 5, true);
        when(menuItemServiceImpl.archiveMenuItemInBarOrder(1L)).thenReturn(archivedMenuItem);

        // Ausfuehrung
        barOrderServiceImpl.archiveBarOrder(1L);

        // Ergebnis Test: BarOrder wurde archiviert
        ArgumentCaptor<BarOrder> captor = ArgumentCaptor.forClass(BarOrder.class);
        verify(barOrderRepository).save(captor.capture());
        BarOrder savedOrder = captor.getValue();
        assert savedOrder != null;
        assertTrue(savedOrder.isArchived());
        assertEquals(1L, savedOrder.getId());
        assertTrue(savedOrder.getItems().get(0).isArchived());
        assertTrue(savedOrder.getItems().get(0).getMenuItem().isArchived());

        // Call Verifikation
        verify(menuItemServiceImpl).archiveMenuItemInBarOrder(1L);
        verify(barOrderRepository).findById(1L);
    }

}
