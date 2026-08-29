package com.example.app.usecases.ports;

import com.example.app.domain.Result;
import java.util.List;

/** Secondary port: order lookup and removal. Adapters implement it; tests use a hand-written fake. */
public interface Orders {
  Result<List<String>, String> recentIds(int limit);

  Result<Void, String> remove(String id);
}
