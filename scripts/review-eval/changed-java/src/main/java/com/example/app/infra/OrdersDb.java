package com.example.app.infra;

import com.example.app.domain.Err;
import com.example.app.domain.Ok;
import com.example.app.domain.Result;
import com.example.app.usecases.ports.Orders;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public final class OrdersDb implements Orders {

  private final Connection connection;

  public OrdersDb(Connection connection) {
    this.connection = connection;
  }

  @Override
  public Result<List<String>, String> recentIds(int limit) {
    try (PreparedStatement query =
        connection.prepareStatement("SELECT id FROM orders ORDER BY created_at DESC LIMIT ?")) {
      query.setInt(1, limit);
      List<String> ids = new ArrayList<>();
      try (ResultSet rows = query.executeQuery()) {
        while (rows.next()) {
          ids.add(rows.getString("id"));
        }
      }
      return new Ok<>(ids);
    } catch (Exception e) {
      return new Err<>("orders query failed");
    }
  }

  @Override
  public Result<Void, String> remove(String id) {
    try (PreparedStatement delete =
        connection.prepareStatement("DELETE FROM orders WHERE id = ?")) {
      delete.setString(1, id);
      delete.executeUpdate();
      return new Ok<>(null);
    } catch (Exception e) {
      return new Err<>("order removal failed");
    }
  }
}
