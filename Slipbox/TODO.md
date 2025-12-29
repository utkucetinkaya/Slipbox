# SlipBox - Development TODOs

## Critical (P0) - Must complete before MVP launch

### iOS App
- [ ] **Complete Inbox UI implementation**
  - [ ] Segments for New/Pending/Approved
  - [ ] Receipt card with swipe actions
  - [ ] Pull-to-refresh
  - [ ] Empty states

- [ ] **Implement Camera Capture**
  - [ ] AVFoundation camera view
  - [ ] Document edge detection (VisionKit)
  - [ ] Crop/rotate interface
  - [ ] Upload progress indicator

- [ ] **Implement Receipt Detail View**
  - [ ] Image viewer with zoom
  - [ ] Edit fields (merchant, date, total, category)
  - [ ] Save/delete actions
  - [ ] Category picker

- [ ] **Implement StoreKit 2 subscription**
  - [ ] Product loading
  - [ ] Purchase flow UI
  - [ ] Transaction validation
  - [ ] Restore purchases
  - [ ] Background transaction listener

- [ ] **Implement Feature Gating**
  - [ ] Read entitlements from Firestore
  - [ ] Show paywall when accessing Pro features
  - [ ] Display Free tier limit warning

- [ ] **Implement Settings Screen**
  - [ ] Profile info
  - [ ] Subscription status
  - [ ] Currency selector
  - [ ] Account deletion flow

### Firebase Backend
- [ ] **Implement real OCR normalization**
  - Currently using placeholder
  - Integrate text parsing for merchant, date, total
  - Handle multiple currencies

- [ ] **Integrate LLM for category suggestion**
  - Currently defaults to "other"
  - Add OpenAI/Gemini API call
  - Implement caching to reduce costs

- [ ] **Implement PDF generation**
  - Currently returns placeholder text
  - Use pdfkit library
  - Add branding/logo

- [ ] **Add rate limiting middleware**
  - Prevent abuse of expensive operations
  - Store counters in Firestore

- [ ] **Add App Check validation middleware**
  - Verify App Check tokens on callable functions
  - Reject requests from non-app clients

- [ ] **Implement StoreKit validation**
  - Currently mocked
  - Integrate with Apple App Store Server API
  - Verify JWS signatures

---

## High Priority (P1) - Important for good UX

### iOS App
- [ ] Add onboarding flow (3 screens)
- [ ] Implement receipt upload from gallery
- [ ] Add category creation/editing
- [ ] Add rule creation UI
- [ ] Implement search/filter in inbox
- [ ] Add haptic feedback
- [ ] Implement localization (TR/EN)
- [ ] Add loading states for all async operations

### Firebase Backend
- [ ] Add deduplication (hash-based)
- [ ] Implement merchant learning (improve suggestions over time)
- [ ] Add export history in Firestore
- [ ] Implement share link revocation
- [ ] Add analytics tracking (events)

---

## Medium Priority (P2) - Nice to have

### iOS App
- [ ] Add widget for quick capture
- [ ] Implement Dark mode support
- [ ] Add receipt image filters/enhancements
- [ ] Create tutorial/help screens
- [ ] Add export history view
- [ ] Implement receipt tags
- [ ] Add custom categories

### Firebase Backend
- [ ] Implement monthly receipt count reset (scheduled function)
- [ ] Add export pagination (for large datasets)
- [ ] Optimize Cloud Functions cold start time
- [ ] Add retry logic for failed processing
- [ ] Implement backup/restore functionality

---

## Low Priority (P3) - Future enhancements

- [ ] Multi-currency advanced features
- [ ] Team/collaboration features (1-3 users)
- [ ] Accountant panel (view multiple clients)
- [ ] Bank integration (optional, region-specific)
- [ ] Recurring expense detection
- [ ] Budget tracking
- [ ] Expense predictions (ML)
- [ ] Apple Watch companion app

---

## Technical Debt
- [ ] Add comprehensive unit tests (iOS)
- [ ] Add Jest tests for Cloud Functions
- [ ] Improve error handling throughout
- [ ] Add logging/monitoring
- [ ] Document all functions
- [ ] Optimize Firestore queries (add indexes)
- [ ] Implement proper retry logic
- [ ] Add circuit breakers for external APIs

---

## Known Issues
- [ ] Receipt normalization is placeholder
- [ ] PDF generation is placeholder
- [ ] StoreKit validation is mocked
- [ ] No real LLM integration yet
- [ ] Missing rate limiting
- [ ] Missing App Check on functions
- [ ] No deduplication implemented
- [ ] No analytics events yet

---

## Before App Store Submission
- [ ] All P0 items complete
- [ ] TestFlight beta testing completed
- [ ] App Store screenshots created
- [ ] App Store description written (TR/EN)
- [ ] Privacy policy published
- [ ] Support website/email set up
- [ ] Demo account created for Apple review
- [ ] All placeholder images replaced with final assets
- [ ] App icon finalized
- [ ] Crashlytics integrated and tested
- [ ] Analytics verified
- [ ] All console warnings fixed
