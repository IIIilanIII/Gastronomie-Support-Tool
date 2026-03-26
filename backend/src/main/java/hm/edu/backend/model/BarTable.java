package hm.edu.backend.model;

import jakarta.persistence.*;

import java.util.Objects;

@Entity
@Table(name = "bar_table")
public class BarTable {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    private Long id;

    public BarTable() {}

    //Für tests
    public BarTable(long id) {
        this.id = id;
    }

    public Long getId() {
        return id;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BarTable barTable = (BarTable) o;
        return Objects.equals(id, barTable.id);
    }
}

