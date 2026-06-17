# Google Ads Account Setup and Billing for the Study

## Status

Operational advisory memo. It explains how Google Ads identity and billing actually
work, why the previous account was deactivated, and a recommended path that keeps the
account compliant while still producing invoices that the university grant office can
reimburse. Tax and VAT specifics below assume an Iberian/Spanish university (tax ID =
**NIF**); confirm the exact jurisdiction before acting, since billing entity and VAT
treatment change the details but not the overall logic.

## TL;DR recommendation

1. **Do not repeat the previous setup.** Putting the university's name on an account
   whose verified owner is your *personal* identity is exactly what triggered the
   deactivation. It is the worst of both worlds: it invites organization verification
   you cannot satisfy on your own.
2. **Pick one of two clean routes, not the broken middle:**
   - **Route A — Individual account (recommended to start):** Account and payments
     profile in *your own name*. Pay with your personal card. Invoices are issued in
     your name. Reimburse as a normal personal research expense, the same way you
     already reimburse cloud/compute charges.
   - **Route B — Institutional account:** Payments profile registered as a *business*
     with the university's legal name and NIF. This is the only way to get the
     university's NIF printed on the Google invoice, but it requires the university to
     authorize you, and Google will ask for documents proving you act on its behalf.
3. **The university NIF on the invoice and "no institutional paperwork" are mutually
   exclusive.** The tax details printed on a Google Ads invoice come from the payments
   profile's business entity, and declaring a business entity is precisely what forces
   organization verification. If the NIF is merely "nice to have," use Route A. If
   finance *requires* the NIF, you must go Route B and get a short authorization.
4. **Talk to the grant administrator with a narrow, low-friction ask** (draft below)
   before assuming Route B is hard. Either they accept personal-name invoices (very
   likely), or they give you a one-page authorization — both are small asks.

## Why the previous attempt was deactivated

Google separates three things that are easy to conflate:

| Layer | What it is | What it controls |
| --- | --- | --- |
| **Google account** | The login (your personal Gmail) | Who signs in and manages campaigns |
| **Payments profile** | The legal/tax entity being billed | Name, address, **tax ID/NIF** on the invoice; whether it is "Individual" or "Business" |
| **Advertiser identity verification** | Google's check of who is really running ads | Whether the account is allowed to serve ads in the EU at all |

Your past setup logged in as you (personal), but named the **university** on the
account/payments side. That declared an organization as the advertiser, so Google's
**advertiser identity verification** (now mandatory for all EU advertisers under the
EU Digital Services Act transparency rules, and separately enforced through payments
verification) asked you to prove you represent that organization — registration
documents, authorization, matching domain, etc. You could not, so the account was
suspended. This is a verification mismatch, not a payment problem.

The lesson: **the name on the account must match an identity you can actually verify.**
You can always verify *yourself*. You can only verify *the university* with the
university's cooperation.

## The fundamental trade-off

```
Want the university NIF on the Google invoice?
        │
        ├── No / "ideally but not required"  ──►  Route A (Individual). Simple. No paperwork.
        │
        └── Yes / finance requires it        ──►  Route B (Institutional). Needs authorization
                                                   + Google org verification.
```

There is no supported way to get a third party's NIF onto the invoice while keeping the
account a personal/individual identity. Any attempt to do so re-creates the mismatch that
got you suspended.

## Options compared

| Option | Whose name on invoice | NIF on invoice | Verification needed | Reimbursement path | Risk |
| --- | --- | --- | --- | --- | --- |
| **A. Individual account** | You | Your NIF/none | Your personal ID only | Personal expense claim | Low |
| **B. Institutional account (you authorized)** | University | University NIF | Org docs + authorization | Direct/institutional invoice | Medium (admin effort) |
| **C. University runs it centrally** | University | University NIF | Handled by their team | Internal | Low risk, possibly slow |
| **D. Personal account + university named** (the old way) | Mismatch | — | Org docs you can't supply | — | **High — repeats suspension** |

Option D is off the table.

## Recommended path

### Step 1 — Default to Route A and just ask finance one question

Before any setup, ask the grant/finance administrator a single concrete question:

> "I need to run small Google Ads charges for a study, billed to my personal card and
> reimbursed from grant [code]. Google will issue monthly invoices **in my name** (not
> the university's), the same way many cloud services bill individuals. Is a
> personal-name Google invoice + card statement sufficient for reimbursement, or does
> the invoice need to carry the university's NIF?"

- **If personal-name invoices are fine** → use **Route A**. Done. This is almost
  certainly the outcome for the small amounts involved and matches how you already get
  cloud/compute reimbursed.
- **If they insist on the university NIF** → move to Step 2 (Route B).

### Step 2 — If the NIF is required, get a minimal authorization (Route B)

You do **not** necessarily need a heavyweight administrative process. Ask for the
smallest artifact that satisfies Google's organization verification:

- A short letter on university letterhead stating that you are authorized to operate a
  Google Ads account on behalf of [University], for research grant [code], signed by an
  appropriate authority (PI, department head, or finance/legal as the institution
  requires).
- The university's legal name, registered address, and **NIF** (and **NIF-IVA / EU VAT
  number** if available — see VAT note).
- Ideally an email address on the university domain you can be reached at, since
  domain-matching helps verification.

Then register the **payments profile as a Business** with those details and complete
verification when prompted. Keep the letter and the university registration extract on
hand to upload.

### Step 3 — Consider Route C if Route B stalls

If authorization turns out to be genuinely bureaucratic, check whether the university's
communications/marketing office already has a Google Ads account or an MCC (manager)
structure. They may be able to create a sub-account for the study, which sidesteps your
personal verification entirely. Slower to arrange but zero suspension risk.

## VAT / invoicing note (Spain / EU)

This is often *why* a finance office wants the NIF, so it is worth understanding:

- Google Ads in the EU is billed by **Google Ireland Ltd**.
- **Business customer with a valid NIF-IVA (EU VAT number):** Google issues the invoice
  under the **reverse-charge** mechanism — no VAT charged by Google; the university
  self-accounts the VAT in Spain. Finance generally *prefers* this, which is why they
  may push for the university NIF on the invoice.
- **Individual / no VAT number:** Google charges VAT on the supply. The invoice is in
  your name and the amount is VAT-inclusive. For a small reimbursable expense this is
  usually still fine, but it is the reason finance may have a mild preference for
  Route B.

If reverse-charge handling is the real driver, that is a strong, legitimate reason to do
Route B — frame the authorization request around correct VAT treatment, which finance
teams care about, rather than around "running ads."

## Operational hygiene (applies to either route)

- **Set a hard budget.** Configure campaign/account budget caps so a misconfiguration
  cannot run up large charges on your personal card.
- **Use a single, identifiable payment card** (ideally one you reserve for reimbursable
  research expenses) so reconciliation against grant [code] is clean.
- **Enable automatic monthly invoices** and download them from
  Billing → Documents each month; do not rely on them remaining available indefinitely.
- **Keep a simple ledger** mapping each Google invoice → card statement line → grant
  reimbursement claim, so the audit trail is self-contained.
- **Complete advertiser verification early**, before launching the experiment, so a
  verification hold does not interrupt live messaging mid-study and corrupt the
  randomization timeline.
- **Document the ad content and targeting** alongside billing, since EU advertiser
  transparency rules now attach your verified identity to the public ad transparency
  record.

## Draft ask for the university administrator

> Subject: Small Google Ads spend for [study name], grant [code]
>
> Hi [name],
>
> For [study name] I need to run a small amount of Google Ads (geo-targeted survey/recruitment
> messaging), on the order of [€X total]. I will pay with my personal card and claim
> reimbursement from grant [code], as I do for cloud/compute services.
>
> Google issues monthly invoices. Two quick questions:
> 1. Is a Google invoice **in my own name** + card statement sufficient for
>    reimbursement, or do you need the invoice to carry the university's **NIF**?
> 2. If you need the university NIF on the invoice, Google requires a short letter
>    confirming I'm authorized to run an ad account on the university's behalf (for
>    correct reverse-charge VAT handling). Could you issue that, and share our legal
>    name, registered address, and NIF / EU VAT number?
>
> Thanks — happy to provide the campaign details and budget cap for the file.

## Open items to confirm

1. Exact tax jurisdiction of the university (assumed Spain/NIF here).
2. Whether finance accepts personal-name invoices for small reimbursables (decides A vs B).
3. Whether the university has an existing Google Ads / MCC account (enables Route C).
4. The university's NIF / NIF-IVA, legal name, and registered address (needed for B).
5. Total expected ad spend and the budget cap to configure.
