# DNS Agriculture Exchange — Roles, Permissions & Navigation

## Authorization rules
1. Authentication identifies the person; the database profile determines their role and status.
2. One primary role per account in the first release.
3. Role selection is not identity verification.
4. Pending users may complete onboarding and view status; restricted trade actions require approval.
5. Suspended users cannot create listings, requests, orders or uploads except allowed appeal/support actions.
6. Users access only records they own, are assigned to, or are explicitly shared with their organization.
7. Admin is owner-granted, never self-selected at public signup.
8. PostgreSQL RLS enforces permissions; frontend guards are only usability controls.

## Capability matrix
| Capability | Farmer | Buyer | Supplier | Processor | Exporter | Investor | Landowner | Agent | Admin |
|---|---|---|---|---|---|---|---|---|---|
| Edit own profile | Yes | Yes | Yes | Yes | Yes | Yes | Yes | Yes | All |
| Create role records | Farm/lots | Sourcing needs | Catalogue | Facility/batches | Export offers | Interest profile | Land parcels | Assigned field records | Moderate |
| Browse approved marketplace | Yes | Yes | Yes | Yes | Yes | Limited | Yes | Assigned scope | All |
| Commercial offers/orders | As seller | As buyer | As supplier | As processor | As exporter | No initial release | Lease enquiries | No | Oversight |
| Quality/document records | Own | Review/feedback | Product docs | Batch QC | Export inspection | Approved pack only | Property docs | Assigned checks | Review |
| Global reporting | No | No | No | No | No | No | No | No | Yes |
| Audit log | Own activity summary | Own summary | Own summary | Own summary | Own summary | Own summary | Own summary | Own summary | Full |

## Portal navigation

### Farmer
Overview; My Farm; Crops & Production; Harvest Forecast; Produce Lots; Buyer Requests; Offers & Orders; Quality & Inspections; Pickup & Delivery; Documents; Notifications; Support; Settings.

### Buyer
Overview; Find Produce; Create Sourcing Request; My Requests; Supplier Offers; Samples & Inspections; Orders; Deliveries; Quality Feedback; Documents; Notifications; Support; Settings.

### Supplier
Overview; Business Profile; Product & Service Catalogue; Inventory/Availability; Enquiries; Quotations; Orders; Fulfilment; Documents & Verification; Notifications; Support; Settings.

### Processor
Overview; Facility Profile; Processing Capacity; Raw Material Requirements; Intake Schedule; Incoming Lots; Production Batches; Output Inventory; Quality Control; Orders & Dispatch; Documents; Notifications; Support; Settings.

### Exporter
Overview; Export Profile; Target Markets; Buyer Requirements; Export Offers; Supplier Network; Lots & Aggregation; Compliance Documents; Inspection & Certification; Shipments; Clearance Milestones; Orders; Notifications; Support; Settings.

### Investor
Overview; Investment Opportunities; Saved Opportunities; Due Diligence Documents; Introductions; Milestones & Updates; Notifications; Support; Settings. Only vetted, consented opportunities are visible.

### Farmland owner
Overview; My Land Parcels; Land Details & Documents; Availability; Lease/Management Enquiries; Site Visits; Offers & Agreements; Notifications; Support; Settings.

### Agent
Overview; My Assignments; Farmer Onboarding; Buyer/Supplier Onboarding; Field Visits; Verification Tasks; Collection & Delivery Updates; Follow-up Queue; Activity Reports; Notifications; Support; Settings. Agents see only assigned records and minimum necessary contact details. They cannot approve their own verification work.

### Administrator
Global Overview; Users & Organizations; Role & Access Management; Verification Queue; Farmer & Farm Registry; Buyer Demand; Supplier Directory; Processor Capacity; Export Opportunities; Land Listings; Agent Assignments; Marketplace Moderation; Orders & Contracts; Samples & Quality; Logistics & Deliveries; Payment Status; Disputes & Support; Market Intelligence; Reports; Audit Log; Platform Settings.

## Status model
Account status: pending, active, rejected, suspended, closed.
Verification status: not_started, submitted, in_review, verified, rejected, expired.
Keep account status separate from document/organization verification status.

## RLS checklist
- Enable RLS on every exposed table.
- Bind personal rows to auth.uid().
- Use organization membership and active membership checks for shared business data.
- Require active assignment rows for agent access.
- Admin access checks a protected admin-membership table or server-managed claim; never a browser-written boolean.
- Restrict writes to allowed columns and valid state transitions.
- Keep Storage private and authorize documents by owner and scope.
- Test that buyers cannot read other buyers' private requests, farmers cannot edit another farm's lots, agents cannot browse unassigned users, and ordinary users cannot read admin data.
