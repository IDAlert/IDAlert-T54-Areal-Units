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

## "Purpose of use": choose Business

During billing signup Google asks for a permanent **Purpose of use**: **Business** or
**Eligible non-business**. For this study, **select Business.**

- Google defines business use as wanting "an economic benefit from your advertising,
  such as increased revenue, sales, or **signups**." Driving signups to the
  citizen-science app is business use in Google's framing — the lack of profit does not
  matter.
- **Eligible non-business** is reserved for *political, charitable, or non-profit*
  activity only. Selecting it effectively asserts non-profit/charitable status, which is
  the option most likely to trigger Google requests for **proof** of that status — the
  documentation burden we want to avoid.
- **Business does not require you to prove you are a company.** This setting is separate
  from Account type (Organization vs Individual) and from advertiser identity
  verification; it only affects VAT treatment.
- **VAT effect:** with **Business**, Google does not add VAT (reverse-charge; you give a
  VAT ID and self-assess) — or, if you sign up as an **Individual** in Spain, you are
  charged the small Spanish indirect tax (~7% + 0.5%). With **Eligible non-business**,
  Google charges VAT at your local rate. Either is a normal reimbursable line.
- The setting is **permanent**, so pick Business and do not rely on changing it later.

Note: Google cannot give tax advice and this memo is not legal/tax advice. If finance has
a specific VAT-handling preference, confirm it, but it does not change the Business choice.

## Ad disclosure name and "who pays": use your own name

Google's signup and verification flow asks two related identity questions — the **legal
name for the ad disclosure** and **who pays for / funds the ads**. For both, the answer
must be **you, in your own legal name.** This is the same principle that caused the prior
suspension: every identity field must match an identity you can actually verify, and you
can only verify *yourself*, not the university or the EC.

### Legal name for ad disclosure

- List **your own legal name**, matching your payments profile and the ID document you
  will submit for verification. Google explicitly suspends accounts when the disclosed
  name does not match submitted documents.
- Do **not** put the university or research group here — that would force organization
  verification (authorization + registration documents) you cannot satisfy alone.

**Public consequence — be clear-eyed about this.** Once verified, Google publishes an
**ad disclosure** and lists you in the public **Ads Transparency Center**
(adstransparency.google.com), searchable by anyone. Per Google's policy, the publicly
available information includes:

- Your **name** and a general **location** (country/region from billing — not your home
  address) shown as the advertiser on each ad.
- **Name change history**.
- **Ad creatives** (the actual ads).
- **Dates and locations** ads served.
- Any ads removed or account suspensions for legal/policy reasons.

Net effect: **your personal name (not the university's) becomes the public face of these
ads.** For a citizen-science recruitment campaign this is normally fine, but if your
ethics protocol or transparency commitments assume the *institution* is the visible
sponsor, that is an argument for the institutional route (Route B) — only viable with
university authorization. There is no compliant way to hide the advertiser entirely;
transparency is mandatory for EU advertisers.

### "Who pays for the ads"

- The **payer of record is the cardholder = you.** You pay with your personal card, so
  list **yourself**.
- Do **not** list the university or the **European Commission / EC grant** as the funder.
  The grant reimbursing you afterwards is an internal arrangement between you and the
  university; naming a third-party funder makes Google treat that entity as the
  advertiser and demands verification of it — repeating the suspension.

| If you list as payer/funder... | Verification Google will require | Feasible alone? |
| --- | --- | --- |
| **Yourself** (recommended) | Your personal photo ID matching profile + disclosure name | Yes |
| **University** | University registration docs + authorization letter | Only with university cooperation (Route B) |
| **EC / "EC grant"** | Proof of that entity's identity and your authority for it | No — would get you suspended |

**Reimbursement is unaffected.** Listing yourself as payer does not jeopardize the claim:
you incurred a legitimate research expense and hold the invoice + card statement, exactly
as with cloud/compute. The EC being the ultimate funding *source* lives in the
university's accounting, not on the Google account.

**One EC-specific caveat:** EC grants typically require **acknowledging EU funding** in
communication/dissemination materials (funding statement and/or EU emblem). That
obligation attaches to the **ad creative and landing page**, not to the Google payer
field. Keep the payer as yourself, but check your grant agreement and add any required EU
funding acknowledgement to the *ad content or its destination page*.

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
