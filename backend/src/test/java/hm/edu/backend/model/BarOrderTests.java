// Java
package hm.edu.backend.model;

import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class BarOrderTests {

    //HILFSMETHODEN
    // BarTable mit gegebener ID erstellen
    private BarTable table(long id) { return new BarTable(id); }

    // MenuItem mit gegebener ID und Name erstellen
    private MenuItem menu(long id, String name) { return new MenuItem(id, name, "desc", 1.0 * id, 1, false); }

    // BarOrderItem mit BarOrder, MenuItem-ID und Quantity erstellen
    private BarOrderItem item(BarOrder order, long menuId, int qty) { return new BarOrderItem(order, menu(menuId, "m" + menuId), qty); }

    /**
     * Konstruktor kopiert Items und Getter/Setter-Funktionalität
     * Expects: korrekte Werte nach Initialisierung und Modifikation, Items-Liste wird kopiert
     */
    @Test
    void ctorCopiesItemsAndExposesGetterSetter() {
        // Testvorbereitung: temporäre BarOrder und BarOrderItem anlegen
        BarOrder tmp = new BarOrder();
        BarOrderItem i1 = item(tmp, 1, 1);

        // Testvorbereitung: BarOrder mit ID, BarTable und Items erstellen
        BarOrder order = new BarOrder(5L, table(3), List.of(i1));

        // Test der initialen Werte und Kopie der Items-Liste
        assertThat(order.getItems()).containsExactly(i1);
        assertThat(order.getItems()).isNotSameAs(List.of(i1));
        assertThat(order.getId()).isEqualTo(5L);
        assertThat(order.getBarTable()).isEqualTo(table(3));
        assertThat(order.isArchived()).isFalse();

        // Modifikation der Werte
        order.setId(6L);
        order.setBarTable(table(4));
        order.setArchived(true);

        // Testvorbereitung: neues BarOrderItem erstellen und setzen
        BarOrderItem i2 = item(order, 2, 2);
        order.setItems(List.of(i2));

        // Test der modifizierten Werte und Kopie der neuen Items-Liste
        assertThat(order.getId()).isEqualTo(6L);
        assertThat(order.getBarTable()).isEqualTo(table(4));
        assertThat(order.isArchived()).isTrue();
        assertThat(order.getItems()).containsExactly(i2);
        assertThat(order.getItems()).isNotSameAs(List.of(i2));
    }

    /**
     * containsMenuItem() prüft auf MenuItem-ID
     * Expects: true für enthaltene MenuItems, false für nicht enthaltene
     */
    @Test
    void containsMenuItemMatchesOnId() {
        // Testvorbereitung: BarOrder mit zwei BarOrderItems anlegen
        BarOrder order = new BarOrder(table(1), List.of());
        BarOrderItem i1 = item(order, 10, 1);
        BarOrderItem i2 = item(order, 20, 2);
        order.setItems(List.of(i1, i2));

        // Test: enthaltene MenuItems liefern true, nicht enthaltene false
        assertThat(order.containsMenuItem(10)).isTrue();
        assertThat(order.containsMenuItem(20)).isTrue();
        assertThat(order.containsMenuItem(99)).isFalse();
    }

    /**
     * equals()-Methode verwendet ID, BarTable, Items und Archived
     * Expects: korrekte Gleichheitsprüfung basierend auf relevanten Attributen
     */
    @Test
    void equalsConsidersIdTableItemsAndArchived() {
        // Testvorbereitung: zwei BarOrders mit gleichen Werten anlegen
        BarOrder a = new BarOrder(1L, table(1), List.of());
        BarOrder b = new BarOrder(1L, table(1), List.of());

        // Test: initiale Gleichheit
        assertThat(a).isEqualTo(b);

        // Test: Vergleich mit sich selbst, null und anderem Typ
        assertThat(a.equals(a)).isTrue();
        assertThat(a.equals(null)).isFalse();
        assertThat(a.equals("other")).isFalse();

        // Test: unterschiedlicher BarTable führt zu Ungleichheit
        b.setBarTable(table(2));
        assertThat(a).isNotEqualTo(b);
        b.setBarTable(table(1));

        // Test: unterschiedliche ID führt zu Ungleichheit
        b.setId(2L);
        assertThat(a).isNotEqualTo(b);
        b.setId(1L);

        // Testvorbereitung: BarOrderItem zu a hinzufügen
        BarOrderItem it = item(a, 1, 1);
        a.setItems(List.of(it));

        // Test: unterschiedliche Items führen zu Ungleichheit
        assertThat(a).isNotEqualTo(b);

        // Testvorbereitung: gleiche Items zu b hinzufügen, aber archived setzen
        b.setItems(List.of(item(b, 1, 1)));
        b.setArchived(true);

        // Test: unterschiedlicher archived-Status führt zu Ungleichheit
        assertThat(a).isNotEqualTo(b);
    }
}
