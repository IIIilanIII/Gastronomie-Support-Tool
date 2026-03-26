package hm.edu.backend.model;

import java.util.List;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class BarOrderItemTests {

    // Hilfsmethode: MenuItem mit gegebener ID erstellen
    private MenuItem menu(long id) {
        return new MenuItem(id, "m" + id, "desc", 1.0 * id, 1, false);
    }

    // Hilfsmethode: BarOrder mit gegebener ID erstellen
    private BarOrder order(long id) {
        return new BarOrder(id, new BarTable(id), List.of());
    }

    /**
     * Konstruktor und Getter/Setter-Funktionalität
     * Expects: korrekte Werte nach Initialisierung und Modifikation
     */
    @Test
    void ctorAndGettersSettersWork() {
        // Testvorbereitung: BarOrder, MenuItem und BarOrderItem anlegen
        BarOrder o = order(1);
        MenuItem m = menu(2);
        BarOrderItem item = new BarOrderItem(o, m, 3);

        // Test der initialen Werte
        assertThat(item.getBarOrder()).isEqualTo(o);
        assertThat(item.getMenuItem()).isEqualTo(m);
        assertThat(item.getQuantity()).isEqualTo(3);
        assertThat(item.isArchived()).isFalse();

        // Modifikation der Werte
        item.setId(10L);
        item.setQuantity(5);
        item.setMenuItem(menu(4));
        item.setBarOrder(order(2));
        item.setArchived(true);

        // Test der modifizierten Werte
        assertThat(item.getId()).isEqualTo(10L);
        assertThat(item.getQuantity()).isEqualTo(5);
        assertThat(item.getMenuItem().getId()).isEqualTo(4L);
        assertThat(item.getBarOrder().getId()).isEqualTo(2L);
        assertThat(item.isArchived()).isTrue();
    }

    /**
     * equals()-Methode verwendet ID, MenuItem, Quantity und Archived
     * Expects: korrekte Gleichheitsprüfung basierend auf relevanten Attributen
     */
    @Test
    void equalsUsesIdMenuItemQuantityAndArchived() {
        // Testvorbereitung: zwei BarOrderItems mit unterschiedlichen BarOrders aber gleichen MenuItems anlegen
        BarOrderItem a = new BarOrderItem(order(1), menu(1), 2);
        BarOrderItem b = new BarOrderItem(order(2), menu(1), 2);

        // Test: gleiche ID führt zu Gleichheit
        a.setId(5L);
        b.setId(5L);
        assertThat(a).isEqualTo(b);

        // Test: unterschiedliche IDs führen zu Ungleichheit
        b.setId(6L);
        assertThat(a).isNotEqualTo(b);

        // Test: unterschiedlicher archived-Status führt zu Ungleichheit
        b.setArchived(true);
        assertThat(a).isNotEqualTo(b);

        // Test: unterschiedliche Quantity führt zu Ungleichheit
        b.setArchived(false);
        b.setQuantity(3);
        assertThat(a).isNotEqualTo(b);

        // Test: Vergleich mit null, anderem Typ und sich selbst
        assertThat(a).isNotEqualTo(null);
        assertThat(a).isNotEqualTo("other");
        assertThat(a).isEqualTo(a);
    }
}
