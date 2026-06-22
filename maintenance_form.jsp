<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.ams.util.DBConnection" %>
<%
    String id = request.getParameter("id");
    boolean isEdit = (id != null && !id.isEmpty());

    String pageTitle = isEdit ? "Edit maintenance ticket" : "Log maintenance ticket";
    String pageSubtitle = isEdit ? "Update this service record" : "Report an issue and send the asset for repair";
    String activePage = "maintenance";

    List<Map<String,Object>> assets = new ArrayList<>();
    List<Map<String,Object>> vendors = new ArrayList<>();
    Map<String,Object> record = null;
    boolean dbOk = true;

    try (Connection con = DBConnection.getConnection()) {

        try (PreparedStatement ps = con.prepareStatement(
                "SELECT asset_id, asset_name FROM assets WHERE status <> 'Disposed' ORDER BY asset_id");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("id", rs.getString("asset_id"));
                m.put("name", rs.getString("asset_name"));
                assets.add(m);
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

        if (isEdit) {
            try (PreparedStatement ps = con.prepareStatement("SELECT * FROM maintenance WHERE maintenance_id = ?")) {
                ps.setInt(1, Integer.parseInt(id));
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        record = new HashMap<>();
                        record.put("maintenance_id", rs.getInt("maintenance_id"));
                        record.put("asset_id", rs.getString("asset_id"));
                        record.put("issue_reported", rs.getString("issue_reported"));
                        record.put("service_date", rs.getDate("service_date"));
                        record.put("completed_date", rs.getDate("completed_date"));
                        record.put("vendor_id", rs.getObject("vendor_id"));
                        record.put("cost", rs.getBigDecimal("cost"));
                        record.put("status", rs.getString("status"));
                        record.put("remarks", rs.getString("remarks"));
                    }
                }
            }
        }

    } catch (Exception ex) {
        dbOk = false;
    }

    if (isEdit && record == null && dbOk) {
        response.sendRedirect("maintenance.jsp");
        return;
    }
%>
<%@ include file="includes/header.jsp" %>

  <div class="card" style="max-width:760px;">
    <div class="card-head">
      <div>
        <h2><%= isEdit ? "Editing ticket #" + record.get("maintenance_id") : "New maintenance ticket" %></h2>
        <div class="hint">Fields marked with <span class="req">*</span> are required.</div>
      </div>
      <a href="maintenance.jsp" class="btn btn-ghost btn-sm">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
        Back to maintenance
      </a>
    </div>

    <div class="card-pad">
      <form action="maintenance_action.jsp" method="post" class="form-grid">
        <input type="hidden" name="op" value="<%= isEdit ? "update" : "create" %>">
        <% if (isEdit) { %><input type="hidden" name="maintenance_id" value="<%= record.get("maintenance_id") %>"><% } %>

        <div class="field full">
          <label for="asset_id">Asset <span class="req">*</span></label>
          <select id="asset_id" name="asset_id" required <%= isEdit ? "disabled" : "" %>>
            <option value="">Select an asset&hellip;</option>
            <% for (Map<String,Object> a : assets) {
                 boolean sel = isEdit && a.get("id").equals(record.get("asset_id"));
            %>
              <option value="<%= a.get("id") %>" <%= sel ? "selected" : "" %>><%= a.get("id") %> &mdash; <%= a.get("name") %></option>
            <% } %>
          </select>
          <% if (isEdit) { %><input type="hidden" name="asset_id" value="<%= record.get("asset_id") %>"><% } %>
        </div>

        <div class="field full">
          <label for="issue_reported">Issue reported <span class="req">*</span></label>
          <input type="text" id="issue_reported" name="issue_reported" required placeholder="e.g. Paper jam and faded print quality"
                 value="<%= isEdit ? record.get("issue_reported") : "" %>">
        </div>

        <div class="field">
          <label for="service_date">Service date <span class="req">*</span></label>
          <input type="date" id="service_date" name="service_date" required
                 value="<%= isEdit ? record.get("service_date") : new java.sql.Date(System.currentTimeMillis()) %>">
        </div>

        <div class="field">
          <label for="vendor_id">Service vendor</label>
          <select id="vendor_id" name="vendor_id">
            <option value="">&mdash; Not specified &mdash;</option>
            <% for (Map<String,Object> v : vendors) {
                 boolean sel = isEdit && record.get("vendor_id") != null && record.get("vendor_id").equals(v.get("id"));
            %>
              <option value="<%= v.get("id") %>" <%= sel ? "selected" : "" %>><%= v.get("name") %></option>
            <% } %>
          </select>
        </div>

        <div class="field">
          <label for="cost">Cost (&#8377;)</label>
          <input type="number" step="0.01" min="0" id="cost" name="cost" placeholder="0.00"
                 value="<%= isEdit && record.get("cost") != null ? record.get("cost") : "" %>">
        </div>

        <div class="field">
          <label for="status">Status</label>
          <select id="status" name="status">
            <% String[] statuses = {"Open","In Progress","Completed"};
               for (String s : statuses) {
                 boolean sel = isEdit ? s.equals(record.get("status")) : "Open".equals(s);
            %>
              <option value="<%= s %>" <%= sel ? "selected" : "" %>><%= s %></option>
            <% } %>
          </select>
          <div class="help">Setting status to Completed returns the asset to service automatically.</div>
        </div>

        <div class="field full">
          <label for="remarks">Remarks</label>
          <textarea id="remarks" name="remarks" rows="3" placeholder="Additional notes about the repair"><%= isEdit && record.get("remarks") != null ? record.get("remarks") : "" %></textarea>
        </div>

        <div class="form-actions full">
          <a href="maintenance.jsp" class="btn btn-ghost">Cancel</a>
          <button type="submit" class="btn btn-accent"><%= isEdit ? "Save changes" : "Log ticket" %></button>
        </div>
      </form>
    </div>
  </div>

<%@ include file="includes/footer.jsp" %>
