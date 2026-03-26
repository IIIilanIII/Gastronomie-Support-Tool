package hm.edu.backend.services;

import hm.edu.backend.model.BarOrder;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

public interface BarOrderService {

    /**
     * Speichert eine neue BarOrder.
     * @param barOrder zu speichernde BarOrder
     * @throws ResponseStatusException 404, wenn ein MenuItem in der BarOrder nicht in DB existiert
     */
    void saveBarOrder(BarOrder barOrder);

    /**
     * Liefert die BarOrder mit der gegebenen ID.
     * @param id die ID der BarOrder
     * @return die gesuchte BarOrder
     * @throws ResponseStatusException 404, wenn die BarOrder nicht existiert
     */
    BarOrder getBarOrderById(long id) throws ResponseStatusException;

    /**
     * Löscht die BarOrder mit der gegebenen ID.
     * @param id die ID der zu löschenden BarOrder
     */
    void deleteBarOrderById(long id);

    /**
     * Aktualisiert eine bestehende BarOrder.
     * @param barOrder BarOrder mit den neuen Daten
     * @throws ResponseStatusException 404, wenn die BarOrder nicht existiert
     */
    void updateBarOrder(BarOrder barOrder);

    /**
     * Liefert alle BarOrders in der Datenbank.
     * @return alle BarOrders
     */
    List<BarOrder> getAllBarOrders();

    /**
     * Archiviert eine BarOrder.
     * @param id BarOrder die archiviert werden soll.
     */
    void archiveBarOrder(Long id);
}


