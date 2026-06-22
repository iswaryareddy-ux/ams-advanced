<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String id = request.getParameter("id");
    String formAction = request.getParameter("action"); // "issue" or null
    boolean isEdit = (id != null && !id.isEmpty());
    boolean isIssue = "issue".equals(formAction);

    String pageTitle = isIssue ? "Issue asset" : (isEdit ? "Edit asset" : "Register new asset");
    String pageSubtitle = isIssue
            ? "Allocate this asset to an employee"
            : (isEdit ? "Update the record for this asset" : "Add a new item to the asset registry");
    String activePage = "assets";

    List<Map<String,Object>> categories = new ArrayList<>();
    List<Map<String,Object>> vendors = new ArrayList<>();
    List<Map<String,Object>> employees = new ArrayList<>();
    Map<String,Object> asset = null;
    String nextId = "AST-1001";
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {

        try (PreparedStatement ps = con.prepareStatement("SELECT category_id, category_name FROM asset_categories ORDER BY category_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("id", rs.getInt("category_id"));
                m.put("name", rs.getString("category_name"));
                categories.add(m);
            }
        }

        try (PreparedStatement ps = con.prepareStatement("SELECT vendor_id, vendor_name FROM vendors ORDER BY vendor_name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("id", rs.getInt("vendor_id"));
                m.put("name", rs.getString("vendor_name"));
                vendors.add(m);
            }
        }

        try (PreparedStatement ps = con.prepareStatement("SELECT employee_id, name, department FROM employees WHERE status='Active' ORDER BY name");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("id", rs.getInt("employee_id"));
                m.put("name", rs.getString("name"));
                m.put("department", rs.getString("department"));
                employees.add(m);
            }
        }

        if (isEdit) {
            try (PreparedStatement ps = con.prepareStatement("SELECT * FROM assets WHERE asset_id = ?")) {
                ps.setString(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        asset = new HashMap<>();
                        asset.put("asset_id", rs.getString("asset_id"));
                        asset.put("asset_name", rs.getString("asset_name"));
                        asset.put("category_id", rs.getInt("category_id"));
                        asset.put("serial_no", rs.getString("serial_no"));
                        asset.put("purchase_date", rs.getDate("purchase_date"));
                        asset.put("purchase_cost", rs.getBigDecimal("purchase_cost"));
                        asset.put("vendor_id", rs.getObject("vendor_id"));
                        asset.put("warranty_expiry", rs.getDate("warranty_expiry"));
                        asset.put("location", rs.getString("location"));
                        asset.put("status", rs.getString("status"));
                    }
                }
            }
        } else {
            // suggest the next Asset ID, e.g. AST-1011
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT asset_id FROM assets WHERE asset_id LIKE 'AST-%' ORDER BY asset_id DESC LIMIT 1");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String last = rs.getString("asset_id");
                    try {
                        int num = Integer.parseInt(last.substring(4)) + 1;
                        nextId = "AST-" + num;
                    } catch (Exception ignore) { }
                }
            }
        }

    } catch (Exception ex) {
        dbOk = false;
    }

    if (isEdit && asset == null && dbOk) {
        response.sendRedirect("assets.jsp");
        return;
    }
%>
<%@ include file="includes/header.jsp" %>

  <% if (!dbOk) { %>
  <div class="alert alert-info">
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>
    <div>Couldn't reach the database. Form options (categories, vendors, employees) may be incomplete.</div>
  </div>
  <% } %>

  <div class="card" style="max-width:760px;">
    <div class="card-head">
      <div>
        <h2><%= isIssue ? "Issue " + id + " to an employee" : (isEdit ? "Editing " + id : "New asset details") %></h2>
        <div class="hint"><%= isIssue ? "The asset status will change to In Use once issued." : "Fields marked with " + "*" + " are required." %></div>
      </div>
      <a href="assets.jsp" class="btn btn-ghost btn-sm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
        Back to assets
      </a>
    </div>

    <div class="card-pad">
    <% if (isIssue) { %>

      <form action="asset_action.jsp" method="post" class="form-grid">
        <input type="hidden" name="op" value="issue">
        <input type="hidden" name="asset_id" value="<%= id %>">

        <div class="field full">
          <label>Asset</label>
          <input type="text" value="<%= id %>" disabled>
        </div>

        <div class="field full">
          <label for="employee_id">Issue to employee <span class="req">*</span></label>
          <select id="employee_id" name="employee_id" required>
            <option value="">Select an employee&hellip;</option>
            <% for (Map<String,Object> e : employees) { %>
              <option value="<%= e.get("id") %>"><%= e.get("name") %> &mdash; <%= e.get("department") %></option>
            <% } %>
          </select>
        </div>

        <div class="field">
          <label for="issue_date">Issue date <span class="req">*</span></label>
          <input type="date" id="issue_date" name="issue_date" required value="<%= new java.sql.Date(System.currentTimeMillis()) %>">
        </div>

        <div class="field">
          <label for="issued_by">Issued by</label>
          <input type="text" id="issued_by" name="issued_by" value="<%= session.getAttribute("username") %>" disabled>
          <input type="hidden" name="issued_by" value="<%= session.getAttribute("username") %>">
        </div>

        <div class="field full">
          <label for="remarks">Remarks</label>
          <textarea id="remarks" name="remarks" rows="3" placeholder="e.g. Replacement for damaged unit, on-boarding kit, etc."></textarea>
        </div>

        <div class="form-actions full">
          <a href="assets.jsp" class="btn btn-ghost">Cancel</a>
          <button type="submit" class="btn btn-accent">Issue asset</button>
        </div>
      </form>

    <% } else { %>

      <form action="asset_action.jsp" method="post" class="form-grid">
        <input type="hidden" name="op" value="<%= isEdit ? "update" : "create" %>">
        <% if (isEdit) { %><input type="hidden" name="original_id" value="<%= id %>"><% } %>

        <div class="field">
          <label for="asset_id">Asset ID <span class="req">*</span></label>
          <input type="text" id="asset_id" name="asset_id" required
                 value="<%= isEdit ? asset.get("asset_id") : nextId %>" <%= isEdit ? "readonly" : "" %> class="mono">
          <% if (!isEdit) { %><div class="help">Suggested ID &mdash; edit if you use a different tagging scheme.</div><% } %>
        </div>

        <div class="field">
          <label for="asset_name">Asset name <span class="req">*</span></label>
          <input type="text" id="asset_name" name="asset_name" required placeholder="e.g. Dell Latitude 5440 Laptop"
                 value="<%= isEdit ? asset.get("asset_name") : "" %>">
        </div>

        <div class="field">
          <label for="category_id">Category <span class="req">*</span></label>
          <select id="category_id" name="category_id" required>
            <% for (Map<String,Object> c : categories) {
                 boolean sel = isEdit && asset.get("category_id").equals(c.get("id"));
            %>
              <option value="<%= c.get("id") %>" <%= sel ? "selected" : "" %>><%= c.get("name") %></option>
            <% } %>
          </select>
        </div>

        <div class="field">
          <label for="serial_no">Serial number</label>
          <input type="text" id="serial_no" name="serial_no" placeholder="Manufacturer serial / asset tag"
                 value="<%= isEdit && asset.get("serial_no") != null ? asset.get("serial_no") : "" %>">
        </div>

        <div class="field">
          <label for="purchase_date">Purchase date</label>
          <input type="date" id="purchase_date" name="purchase_date"
                 value="<%= isEdit && asset.get("purchase_date") != null ? asset.get("purchase_date") : "" %>">
        </div>

        <div class="field">
          <label for="purchase_cost">Purchase cost (&#8377;)</label>
          <input type="number" step="0.01" min="0" id="purchase_cost" name="purchase_cost" placeholder="0.00"
                 value="<%= isEdit && asset.get("purchase_cost") != null ? asset.get("purchase_cost") : "" %>">
        </div>

        <div class="field">
          <label for="vendor_id">Vendor</label>
          <select id="vendor_id" name="vendor_id">
            <option value="">&mdash; Not specified &mdash;</option>
            <% for (Map<String,Object> v : vendors) {
                 boolean sel = isEdit && asset.get("vendor_id") != null && asset.get("vendor_id").equals(v.get("id"));
            %>
              <option value="<%= v.get("id") %>" <%= sel ? "selected" : "" %>><%= v.get("name") %></option>
            <% } %>
          </select>
        </div>

        <div class="field">
          <label for="warranty_expiry">Warranty expiry</label>
          <input type="date" id="warranty_expiry" name="warranty_expiry"
                 value="<%= isEdit && asset.get("warranty_expiry") != null ? asset.get("warranty_expiry") : "" %>">
        </div>

        <div class="field">
          <label for="location">Location</label>
          <input type="text" id="location" name="location" placeholder="e.g. IT Department, Server Room"
                 value="<%= isEdit && asset.get("location") != null ? asset.get("location") : "" %>">
        </div>

        <% if (isEdit) { %>
        <div class="field">
          <label for="status">Status <span class="req">*</span></label>
          <select id="status" name="status" required>
            <% String[] statuses = {"Available","In Use","Under Repair","Disposed"};
               for (String s : statuses) {
                 boolean sel = s.equals(asset.get("status"));
            %>
              <option value="<%= s %>" <%= sel ? "selected" : "" %>><%= s %></option>
            <% } %>
          </select>
          <div class="help">Changing status here does not update employee allocation &mdash; use the issue/return actions for that.</div>
        </div>
        <% } %>

        <div class="form-actions full">
          <a href="assets.jsp" class="btn btn-ghost">Cancel</a>
          <button type="submit" class="btn btn-accent"><%= isEdit ? "Save changes" : "Register asset" %></button>
        </div>
      </form>

    <% } %>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>
