<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String pageTitle = "Vendors";
    String pageSubtitle = "Suppliers and service providers linked to your assets";
    String activePage = "vendors";

    String flash = request.getParameter("flash");
    List<Map<String,Object>> vendors = new ArrayList<>();
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {
        String sql = "SELECT v.vendor_id, v.vendor_name, v.contact_person, v.phone, v.email, v.address, " +
                      "(SELECT COUNT(*) FROM assets a WHERE a.vendor_id = v.vendor_id) AS asset_count, " +
                      "(SELECT COUNT(*) FROM maintenance m WHERE m.vendor_id = v.vendor_id) AS service_count " +
                      "FROM vendors v ORDER BY v.vendor_name";
        try (PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("vendor_id", rs.getInt("vendor_id"));
                row.put("vendor_name", rs.getString("vendor_name"));
                row.put("contact_person", rs.getString("contact_person"));
                row.put("phone", rs.getString("phone"));
                row.put("email", rs.getString("email"));
                row.put("address", rs.getString("address"));
                row.put("asset_count", rs.getInt("asset_count"));
                row.put("service_count", rs.getInt("service_count"));
                vendors.add(row);
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

  <% if ("added".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Vendor added.</div>
  </div>
  <% } else if ("updated".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Vendor details updated.</div>
  </div>
  <% } else if ("deleted".equals(flash)) { %>
  <div class="alert alert-success" data-autohide>
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
    <div>Vendor removed.</div>
  </div>
  <% } else if ("blocked".equals(flash)) { %>
  <div class="alert alert-error">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
    <div>This vendor is linked to assets or maintenance records and cannot be removed.</div>
  </div>
  <% } %>

  <div class="card">
    <div class="card-head">
      <div>
        <h2>Vendor directory</h2>
        <div class="hint"><%= vendors.size() %> vendor<%= vendors.size() == 1 ? "" : "s" %> on record</div>
      </div>
      <a href="vendor_form.jsp" class="btn btn-accent">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
        Add vendor
      </a>
    </div>

    <div class="toolbar">
      <div class="search">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
        <input type="text" placeholder="Search by vendor, contact or email" data-table-search="vendorTable">
      </div>
    </div>

    <div class="table-wrap">
      <table id="vendorTable">
        <thead>
          <tr>
            <th>Vendor</th>
            <th>Contact person</th>
            <th>Phone</th>
            <th>Email</th>
            <th>Assets supplied</th>
            <th>Service records</th>
            <th style="text-align:right;">Actions</th>
          </tr>
        </thead>
        <tbody>
        <% if (vendors.isEmpty()) { %>
          <tr><td colspan="7">
            <div class="empty-state">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9 12 3l9 6"/><path d="M5 9v11h14V9"/><path d="M9 20v-6h6v6"/></svg>
              <h3>No vendors yet</h3>
              <p>Add suppliers and service providers to link them to assets and maintenance records.</p>
            </div>
          </td></tr>
        <% } else {
            for (Map<String,Object> v : vendors) {
        %>
          <tr>
            <td>
              <div class="cell-primary"><%= v.get("vendor_name") %></div>
              <div class="cell-sub"><%= v.get("address") != null ? v.get("address") : "" %></div>
            </td>
            <td><%= v.get("contact_person") != null ? v.get("contact_person") : "&mdash;" %></td>
            <td class="mono cell-sub"><%= v.get("phone") != null ? v.get("phone") : "&mdash;" %></td>
            <td class="cell-sub"><%= v.get("email") != null ? v.get("email") : "&mdash;" %></td>
            <td><span class="tag"><%= v.get("asset_count") %> assets</span></td>
            <td><span class="tag"><%= v.get("service_count") %> records</span></td>
            <td>
              <div class="row-actions">
                <a class="icon-btn" title="Edit" href="vendor_form.jsp?id=<%= v.get("vendor_id") %>">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </a>
                <form action="vendor_action.jsp" method="post" style="display:inline;" data-confirm="Remove <%= v.get("vendor_name") %> from the vendor directory?">
                  <input type="hidden" name="op" value="delete">
                  <input type="hidden" name="vendor_id" value="<%= v.get("vendor_id") %>">
                  <button class="icon-btn danger" title="Delete">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>
                  </button>
                </form>
              </div>
            </td>
          </tr>
        <% } } %>
        </tbody>
      </table>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>
