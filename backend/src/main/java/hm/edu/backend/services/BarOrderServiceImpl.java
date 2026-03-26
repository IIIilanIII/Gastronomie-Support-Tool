package hm.edu.backend.services;

import hm.edu.backend.model.BarOrder;
import hm.edu.backend.model.BarOrderItem;
import hm.edu.backend.model.MenuItem;
import hm.edu.backend.repositories.BarOrderRepository;
import hm.edu.backend.repositories.MenuItemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import java.util.List;

@Service
public class BarOrderServiceImpl implements BarOrderService {

    @Autowired
    private BarOrderRepository barOrderRepository;

    @Autowired
    private MenuItemRepository menuItemRepository;

    @Autowired
    private MenuItemService menuItemService;

    /**
     * Speichert eine neue BarOrder.
     * @param barOrder zu speichernde BarOrder
     * @throws ResponseStatusException 404, wenn ein MenuItem in der BarOrder nicht in DB existiert
     */
    @Override
    public void saveBarOrder(BarOrder barOrder) {
        for (BarOrderItem item : barOrder.getItems()) {

            // 1) echtes MenuItem laden
            Long menuId = item.getMenuItem().getId();
            MenuItem menu = menuItemService.getMenuItemById(menuId);

            // 2) in BarOrderItem ersetzen
            item.setMenuItem(menu);

            // 3) Beziehung setzen
            item.setBarOrder(barOrder);
        }
        barOrderRepository.save(barOrder);
    }

    /**
     * Liefert die BarOrder mit der gegebenen ID.
     * @param id die ID der BarOrder
     * @return die gesuchte BarOrder
     * @throws ResponseStatusException 404, wenn die BarOrder nicht existiert
     */
    @Override
    public BarOrder getBarOrderById(long id) throws ResponseStatusException {
        return barOrderRepository.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Bar Order does not exist"));
    }

    /**
     * Löscht die BarOrder mit der gegebenen ID.
     * @param id die ID der zu löschenden BarOrder
     */
    @Override
    public void deleteBarOrderById(long id) {
        barOrderRepository.deleteById(id);
    }

    /**
     * Aktualisiert eine bestehende BarOrder.
     * @param barOrder BarOrder mit den neuen Daten
     * @throws ResponseStatusException 404, wenn die BarOrder nicht existiert
     */
    @Override
    public void updateBarOrder(BarOrder barOrder) {
        // sicherstellen, dass die BarOrder existiert
        getBarOrderById(barOrder.getId());
        barOrderRepository.save(barOrder);
    }

    /**
     * Liefert alle BarOrders in der Datenbank.
     * @return alle BarOrders
     */
    @Override
    public List<BarOrder> getAllBarOrders() {
        return barOrderRepository.findAll();
    }

    /**
     * Archiviert eine BarOrder.
     * @param id BarOrder die archiviert werden soll.
     */
    @Override
    public void archiveBarOrder(Long id) {
        BarOrder barOrder = this.getBarOrderById(id);
        BarOrder archivedBarOrder = new BarOrder(barOrder.getId(),barOrder.getBarTable(), barOrder.getItems());
        // Archiviere jedes MenuItem in der BarOrder
        for (BarOrderItem item : archivedBarOrder.getItems()) {
            MenuItem archivedItem = menuItemService.archiveMenuItemInBarOrder(item.getMenuItem().getId());
            item.setMenuItem(archivedItem);
            item.setArchived(true);
        }
        archivedBarOrder.setArchived(true);
        barOrderRepository.save(archivedBarOrder);
    }
}