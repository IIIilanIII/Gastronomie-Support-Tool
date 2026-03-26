package hm.edu.backend.model;

import jakarta.persistence.*;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

import java.util.Objects;

@Entity
@Table (name = "menu_item")
public class MenuItem {
    @Id
    @GeneratedValue (strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    private String name;

    @NotNull
    private String description;

    @NotNull
    @PositiveOrZero
    private double price;

    @Min(1)
    private int version;
    private boolean archived = false;

    public MenuItem() {}

    public MenuItem(long id, String name, String description, double price, int version, boolean archived) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.price = price;
        this.version = version;
        this.archived = archived;
    }

    public MenuItem(String name, String description, double price, int version, boolean archived) {
        this.name = name;
        this.description = description;
        this.price = price;
        this.version = version;
        this.archived = archived;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public double getPrice() {
        return price;
    }

    public int getVersion() {
        return version;
    }

    public boolean isArchived() {
        return archived;
    }

    public void setArchived(boolean archived) {
        this.archived = archived;
    }

    public void setPrice(double price) {
        this.price = price;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        MenuItem menuItem = (MenuItem) o;
        return Double.compare(price, menuItem.price) == 0 && version == menuItem.version && archived == menuItem.archived && Objects.equals(id, menuItem.id) && Objects.equals(name, menuItem.name) && Objects.equals(description, menuItem.description);
    }

}
