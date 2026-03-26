package hm.edu.backend.model;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class MenuItemTests {

    /**
     * Konstruktor und Getter/Setter-Funktionalität
     * Expects: korrekte Werte nach Initialisierung und Modifikation
     */
    @Test
    void ctorAndGettersSettersWork() {
        // Testvorbereitung: MenuItem ohne ID erstellen
        MenuItem item = new MenuItem("n1", "d1", 1.5, 2, false);

        // Test der initialen Werte
        assertThat(item.getId()).isNull();
        assertThat(item.getName()).isEqualTo("n1");
        assertThat(item.getDescription()).isEqualTo("d1");
        assertThat(item.getPrice()).isEqualTo(1.5);
        assertThat(item.getVersion()).isEqualTo(2);
        assertThat(item.isArchived()).isFalse();

        // Modifikation der Werte
        item.setId(10L);
        item.setName("n2");
        item.setDescription("d2");
        item.setPrice(3.0);
        item.setArchived(true);

        // Test der modifizierten Werte
        assertThat(item.getId()).isEqualTo(10L);
        assertThat(item.getName()).isEqualTo("n2");
        assertThat(item.getDescription()).isEqualTo("d2");
        assertThat(item.getPrice()).isEqualTo(3.0);
        assertThat(item.isArchived()).isTrue();
    }

    /**
     * equals()-Methode verwendet alle Felder
     * Expects: korrekte Gleichheitsprüfung basierend auf allen Attributen
     */
    @Test
    void equalsCoversAllFields() {
        // Testvorbereitung: zwei MenuItems mit gleichen Werten anlegen
        MenuItem a = new MenuItem(1L, "n", "d", 1.0, 1, false);
        MenuItem b = new MenuItem(1L, "n", "d", 1.0, 1, false);

        // Test: initiale Gleichheit und Vergleich mit sich selbst, null und anderem Typ
        assertThat(a).isEqualTo(b);
        assertThat(a).isEqualTo(a);
        assertThat(a).isNotEqualTo(null);
        assertThat(a).isNotEqualTo("other");

        // Test: unterschiedlicher Name führt zu Ungleichheit
        b.setName("other");
        assertThat(a).isNotEqualTo(b);
        b.setName("n");

        // Test: unterschiedliche Description führt zu Ungleichheit
        b.setDescription("other");
        assertThat(a).isNotEqualTo(b);
        b.setDescription("d");

        // Test: unterschiedlicher Price führt zu Ungleichheit
        b.setPrice(2.0);
        assertThat(a).isNotEqualTo(b);
        b.setPrice(1.0);

        // Testvorbereitung: MenuItem mit unterschiedlicher Version, archived und ID anlegen
        MenuItem c = new MenuItem(1L, "n", "d", 1.0, 2, false);
        MenuItem d = new MenuItem(1L, "n", "d", 1.0, 1, true);
        MenuItem e = new MenuItem(2L, "n", "d", 1.0, 1, false);

        // Test: unterschiedliche Version, archived und ID führen zu Ungleichheit
        assertThat(a).isNotEqualTo(c);
        assertThat(a).isNotEqualTo(d);
        assertThat(a).isNotEqualTo(e);
    }
}
