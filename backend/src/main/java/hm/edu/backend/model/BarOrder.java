package hm.edu.backend.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@Entity
@Table (name = "bar_order")
public class BarOrder {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "BarTable darf nicht null sein")
    @ManyToOne
    private BarTable barTable;

    @Valid
    @OneToMany(mappedBy = "barOrder", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private List<BarOrderItem> items = new ArrayList<>();


    boolean archived = false;

    public BarOrder() {}

    public BarOrder(long id, BarTable barTable, List<BarOrderItem> items) {
        this.id = id;
        this.barTable = barTable;
        this.items = new ArrayList<>(items);
    }

    public BarOrder(BarTable barTable, List<BarOrderItem> items) {
        this.barTable = barTable;
        this.items = new ArrayList<>(items);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public List<BarOrderItem> getItems() {
        return items;
    }

    public void setItems(List<BarOrderItem> items) {
        this.items = new ArrayList<>(items);
    }

    public BarTable getBarTable() {
        return barTable;
    }

    public void setBarTable(BarTable barTable) {this.barTable = barTable;}

    public boolean isArchived() {
        return this.archived;
    }

    public void setArchived(boolean archived) {
        this.archived = archived;
    }

    public boolean containsMenuItem(long id) {
        return items.stream().anyMatch(barOrderItem -> barOrderItem.getMenuItem().getId() == id);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BarOrder barOrder = (BarOrder) o;
        return archived == barOrder.archived && Objects.equals(id, barOrder.id) && Objects.equals(barTable, barOrder.barTable) && Objects.equals(items, barOrder.items);
    }

}
