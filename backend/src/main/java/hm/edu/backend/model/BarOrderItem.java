package hm.edu.backend.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.util.Objects;

@Entity
@Table(name = "bar_order_item")
public class BarOrderItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotNull(message = "MenuItem darf nicht null sein")
    @ManyToOne
    private MenuItem menuItem;

    @Positive(message = "Menge muss positiv sein")
    private int quantity;

    @ManyToOne
    @JsonBackReference
    private BarOrder barOrder;

    private boolean archived = false;

    public BarOrderItem() {

    }

    public BarOrderItem(BarOrder barOrder, MenuItem menuItem, int quantity) {
        this.barOrder = barOrder;
        this.menuItem = menuItem;
        this.quantity = quantity;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public BarOrder getBarOrder() {
        return barOrder;
    }
    public void setBarOrder(BarOrder barOrder) {
        this.barOrder = barOrder;
    }

    public MenuItem getMenuItem() {
        return menuItem;
    }

    public void setMenuItem(MenuItem menuItem) {
        this.menuItem = menuItem;
    }

    public void setArchived(boolean archived) {
        this.archived = archived;
    }

    public boolean isArchived() { return archived; }



    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    @Override
    // BarOrder ignorieren, damit keine Endlosschleife entsteht
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        BarOrderItem that = (BarOrderItem) o;
        return quantity == that.quantity && archived == that.archived && Objects.equals(id, that.id) && this.menuItem.equals(that.menuItem);
    }
}
