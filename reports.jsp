<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.math.RoundingMode" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String pageTitle = "Reports";
    String pageSubtitle = "Generate point-in-time views of the asset register";
    String activePage = "reports";

    String type = request.getParameter("type");
    if (type == null || type.isEmpty()) type = "available";

    List<Map<String,Object>> rows = new ArrayList<>();
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {

        switch (type) {

            case "assigned": {
                String sql = "SELECT a.asset_id, a.asset_name, c.category_name, e.name AS employee_name, " +
                              "e.department, al.issue_date " +
                              "FROM assets a " +
                              "JOIN asset_categories c ON c.category_id = a.category_id " +
                              "JOIN employees e ON e.employee_id = a.assigned_to " +
                              "LEFT JOIN asset_allocations al ON al.asset_id = a.asset_id AND al.return_date IS NULL " +
                              "WHERE a.status = 'In Use' ORDER BY e.name";
                try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> r = new HashMap<>();
                        r.put("asset_id", rs.getString("asset_id"));
                        r.put("asset_name", rs.getString("asset_name"));
                        r.put("category_name", rs.getString("category_name"));
                        r.put("employee_name", rs.getString("employee_name"));
                        r.put("department", rs.getString("department"));
                        r.put("issue_date", rs.getDate("issue_date"));
                        rows.add(r);
                    }
                }
                break;
            }

            case "repair": {
                String sql = "SELECT a.asset_id, a.asset_name, c.category_name, m.issue_reported, m.service_date, v.vendor_name, m.status " +
                              "FROM assets a " +
                              "JOIN asset_categories c ON c.category_id = a.category_id " +
                              "LEFT JOIN maintenance m ON m.asset_id = a.asset_id AND m.status <> 'Completed' " +
                              "LEFT JOIN vendors v ON v.vendor_id = m.vendor_id " +
                              "WHERE a.status = 'Under Repair' ORDER BY a.asset_id";
                try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> r = new HashMap<>();
                        r.put("asset_id", rs.getString("asset_id"));
                        r.put("asset_name", rs.getString("asset_name"));
                        r.put("category_name", rs.getString("category_name"));
                        r.put("issue_reported", rs.getString("issue_reported"));
                        r.put("service_date", rs.getDate("service_date"));
                        r.put("vendor_name", rs.getString("vendor_name"));
                        r.put("status", rs.getString("status"));
                        rows.add(r);
                    }
                }
                break;
            }

            case "depreciation": {
                String sql = "SELECT a.asset_id, a.asset_name, c.category_name, a.purchase_date, a.purchase_cost, c.depreciation_rate " +
                              "FROM assets a JOIN asset_categories c ON c.category_id = a.category_id " +
                              "WHERE a.purchase_cost > 0 AND a.status <> 'Disposed' ORDER BY a.asset_id";
                try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> r = new HashMap<>();
                        java.sql.Date pd = rs.getDate("purchase_date");
                        BigDecimal cost = rs.getBigDecimal("purchase_cost");
                        BigDecimal rate = rs.getBigDecimal("depreciation_rate");

                        double years = 0;
                        if (pd != null) {
                            long days = (System.currentTimeMillis() - pd.getTime()) / (1000L*60*60*24);
                            years = days / 365.25;
                        }
                        BigDecimal depreciated = cost.multiply(rate).multiply(BigDecimal.valueOf(years)).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
                        if (depreciated.compareTo(cost) > 0) depreciated = cost;
                        BigDecimal currentValue = cost.subtract(depreciated);
                        if (currentValue.compareTo(BigDecimal.ZERO) < 0) currentValue = BigDecimal.ZERO;

                        r.put("asset_id", rs.getString("asset_id"));
                        r.put("asset_name", rs.getString("asset_name"));
                        r.put("category_name", rs.getString("category_name"));
                        r.put("purchase_date", pd);
                        r.put("purchase_cost", cost);
                        r.put("rate", rate);
                        r.put("years", years);
                        r.put("current_value", currentValue);
                        rows.add(r);
                    }
                }
                break;
            }

            case "audit": {
                String sql = "SELECT username, action, entity, entity_id, details, created_at FROM audit_log ORDER BY created_at DESC LIMIT 50";
                try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> r = new HashMap<>();
                        r.put("username", rs.getString("username"));
                        r.put("action", rs.getString("action"));
                        r.put("entity", rs.getString("entity"));
                        r.put("entity_id", rs.getString("entity_id"));
                        r.put("details", rs.getString("details"));
                        r.put("created_at", rs.getTimestamp("created_at"));
                        rows.add(r);
                    }
                }
                break;
            }

            default: { // available
                type = "available";
                String sql = "SELECT a.asset_id, a.asset_name, c.category_name, a.location, a.warranty_expiry " +
                              "FROM assets a JOIN asset_categories c ON c.category_id = a.category_id " +
                              "WHERE a.status = 'Available' ORDER BY a.asset_id";
                try (PreparedStatement ps = con.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Map<String,Object> r = new HashMap<>();
                        r.put("asset_id", rs.getString("asset_id"));
                        r.put("asset_name", rs.getString("asset_name"));
                        r.put("category_name", rs.getString("category_name"));
                        r.put("location", rs.getString("location"));
                        r.put("warranty_expiry", rs.getDate("warranty_expiry"));
                        rows.add(r);
                    }
                }
            }
        }

    } catch (Exception ex) {
        dbOk = false;
    }
%>
<%@ include file="includes/header.jsp" %>

  <% if (!dbOk) { %>
  <div class="alert alert-info">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    <div>Couldn't reach the database. Confirm <span class="mono">db.properties</span> is configured correctly.</div>
  </div>
  <% } %>

  <div class="card">
    <div class="card-head">
      <div>
        <h2>Report viewer</h2>
        <div class="hint">Choose a report, then use your browser's print dialog to export as PDF.</div>
      </div>
      <button class="btn btn-ghost btn-sm" onclick="window.print()">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>
        Print / export
      </button>
    </div>

    <div class="toolbar" style="gap:.5rem;">
      <a href="reports.jsp?type=available" class="btn btn-sm <%= "available".equals(type) ? "btn-primary" : "btn-ghost" %>">Available assets</a>
      <a href="reports.jsp?type=assigned" class="btn btn-sm <%= "assigned".equals(type) ? "btn-primary" : "btn-ghost" %>">Assigned assets</a>
      <a href="reports.jsp?type=repair" class="btn btn-sm <%= "repair".equals(type) ? "btn-primary" : "btn-ghost" %>">Faulty / under repair</a>
      <a href="reports.jsp?type=depreciation" class="btn btn-sm <%= "depreciation".equals(type) ? "btn-primary" : "btn-ghost" %>">Depreciation</a>
      <a href="reports.jsp?type=audit" class="btn btn-sm <%= "audit".equals(type) ? "btn-primary" : "btn-ghost" %>">Audit trail</a>
    </div>

    <div class="table-wrap">
    <% if ("assigned".equals(type)) { %>
      <table>
        <thead><tr><th>Asset ID</th><th>Asset</th><th>Category</th><th>Assigned to</th><th>Department</th><th>Issued on</th></tr></thead>
        <tbody>
        <% if (rows.isEmpty()) { %><tr><td colspan="6"><div class="empty-state"><h3>No assets currently assigned</h3></div></td></tr><% }
           for (Map<String,Object> r : rows) { %>
          <tr>
            <td><span class="tag"><%= r.get("asset_id") %></span></td>
            <td class="cell-primary"><%= r.get("asset_name") %></td>
            <td><%= r.get("category_name") %></td>
            <td><%= r.get("employee_name") %></td>
            <td><%= r.get("department") != null ? r.get("department") : "&mdash;" %></td>
            <td class="cell-sub"><%= r.get("issue_date") != null ? r.get("issue_date") : "&mdash;" %></td>
          </tr>
        <% } %>
        </tbody>
      </table>

    <% } else if ("repair".equals(type)) { %>
      <table>
        <thead><tr><th>Asset ID</th><th>Asset</th><th>Category</th><th>Issue reported</th><th>Since</th><th>Vendor</th><th>Status</th></tr></thead>
        <tbody>
        <% if (rows.isEmpty()) { %><tr><td colspan="7"><div class="empty-state"><h3>Nothing under repair</h3><p>All assets are in good standing.</p></div></td></tr><% }
           for (Map<String,Object> r : rows) { %>
          <tr>
            <td><span class="tag"><%= r.get("asset_id") %></span></td>
            <td class="cell-primary"><%= r.get("asset_name") %></td>
            <td><%= r.get("category_name") %></td>
            <td><%= r.get("issue_reported") != null ? r.get("issue_reported") : "&mdash;" %></td>
            <td class="cell-sub"><%= r.get("service_date") != null ? r.get("service_date") : "&mdash;" %></td>
            <td><%= r.get("vendor_name") != null ? r.get("vendor_name") : "&mdash;" %></td>
            <td><span class="status status-repair"><%= r.get("status") != null ? r.get("status") : "Under Repair" %></span></td>
          </tr>
        <% } %>
        </tbody>
      </table>

    <% } else if ("depreciation".equals(type)) { %>
      <table>
        <thead><tr><th>Asset ID</th><th>Asset</th><th>Category</th><th>Purchase date</th><th>Cost</th><th>Rate / yr</th><th>Age</th><th>Current value</th></tr></thead>
        <tbody>
        <% if (rows.isEmpty()) { %><tr><td colspan="8"><div class="empty-state"><h3>No cost data available</h3><p>Add purchase cost when registering assets to see depreciation.</p></div></td></tr><% }
           for (Map<String,Object> r : rows) {
              double years = (Double) r.get("years");
        %>
          <tr>
            <td><span class="tag"><%= r.get("asset_id") %></span></td>
            <td class="cell-primary"><%= r.get("asset_name") %></td>
            <td><%= r.get("category_name") %></td>
            <td class="cell-sub"><%= r.get("purchase_date") != null ? r.get("purchase_date") : "&mdash;" %></td>
            <td class="mono">&#8377;<%= r.get("purchase_cost") %></td>
            <td class="mono"><%= r.get("rate") %>%</td>
            <td class="cell-sub"><%= String.format("%.1f yrs", years) %></td>
            <td class="mono cell-primary">&#8377;<%= r.get("current_value") %></td>
          </tr>
        <% } %>
        </tbody>
      </table>
      <div class="card-pad" style="border-top:1px solid var(--line);">
        <p class="field help">Straight-line depreciation: current value = purchase cost &minus; (cost &times; category rate &times; age in years &divide; 100), floored at &#8377;0. Adjust rates per category in <span class="mono">asset_categories</span>.</p>
      </div>

    <% } else if ("audit".equals(type)) { %>
      <table>
        <thead><tr><th>When</th><th>User</th><th>Action</th><th>Entity</th><th>Details</th></tr></thead>
        <tbody>
        <% if (rows.isEmpty()) { %><tr><td colspan="5"><div class="empty-state"><h3>No audit history yet</h3></div></td></tr><% }
           for (Map<String,Object> r : rows) { %>
          <tr>
            <td class="cell-sub"><%= r.get("created_at") %></td>
            <td><%= r.get("username") %></td>
            <td><span class="tag"><%= r.get("action") %></span></td>
            <td><%= r.get("entity") %> <span class="mono cell-sub"><%= r.get("entity_id") != null ? r.get("entity_id") : "" %></span></td>
            <td class="cell-sub"><%= r.get("details") %></td>
          </tr>
        <% } %>
        </tbody>
      </table>

    <% } else { %>
      <table>
        <thead><tr><th>Asset ID</th><th>Asset</th><th>Category</th><th>Location</th><th>Warranty</th></tr></thead>
        <tbody>
        <% if (rows.isEmpty()) { %><tr><td colspan="5"><div class="empty-state"><h3>No available assets</h3><p>Everything is currently assigned, under repair, or disposed.</p></div></td></tr><% }
           for (Map<String,Object> r : rows) { %>
          <tr>
            <td><span class="tag"><%= r.get("asset_id") %></span></td>
            <td class="cell-primary"><%= r.get("asset_name") %></td>
            <td><%= r.get("category_name") %></td>
            <td><%= r.get("location") != null ? r.get("location") : "&mdash;" %></td>
            <td class="cell-sub"><%= r.get("warranty_expiry") != null ? r.get("warranty_expiry") : "&mdash;" %></td>
          </tr>
        <% } %>
        </tbody>
      </table>
    <% } %>
    </div>

    <div class="pagination">
      <span><%= rows.size() %> row<%= rows.size() == 1 ? "" : "s" %></span>
      <span class="mono">Generated <%= new java.util.Date() %></span>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>
