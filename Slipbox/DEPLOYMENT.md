# SlipBox - Deployment Checklist

## Pre-Deployment

### Firebase
- [ ] Firebase project created
- [ ] Firestore database created
- [ ] Storage bucket created
- [ ] Authentication providers enabled (Apple, Email)
- [ ] App Check enabled
- [ ] Upgraded to Blaze plan
- [ ] Budget alerts configured

### iOS App
- [ ] Bundle ID registered in Apple Developer
- [ ] App created in App Store Connect
- [ ] In-App Purchases created
- [ ] Server Notification URL configured
- [ ] GoogleService-Info.plist downloaded and added
- [ ] Signing certificates configured
- [ ] App icons created (1024x1024)
- [ ] Screenshots taken (all required sizes)

---

## Deployment Steps

### 1. Deploy Firebase Backend
```bash
cd firebase-backend

# Deploy rules first
firebase deploy --only firestore:rules,storage:rules

# Deploy functions
firebase deploy --only functions

# Deploy hosting
firebase deploy --only hosting
```

**Verify:**
- [ ] Functions appear in Firebase Console
- [ ] Rules are active in Firestore
- [ ] Hosting site is accessible

### 2. Configure Environment
```bash
# Set production environment variables
firebase functions:config:set \\
  openai.key="YOUR_API_KEY" \\
  app.url="https://YOUR_PROJECT.web.app"

# Redeploy functions with new config
firebase deploy --only functions
```

### 3. Test Backend
- [ ] Call `initializeUser` function (creates test user)
- [ ] Upload test receipt to Storage
- [ ] Verify `processReceipt` triggers
- [ ] Test `generateExport` function
- [ ] Test share link viewer at `/s/test`

### 4. Build iOS App
```bash
# In Xcode:
# 1. Select "Any iOS Device" as target
# 2. Product → Archive
# 3. Distribute App → App Store Connect
# 4. Upload
```

**Verify:**
- [ ] No build errors
- [ ] No warnings (or acceptable warnings)
- [ ] Archive uploads successfully

### 5. App Store Connect Setup

#### App Information
- [ ] Category: Finance or Productivity
- [ ] Privacy Policy URL
- [ ] Support URL

#### Pricing & Availability
- [ ] Select countries
- [ ] Pricing (Free with IAP)

#### App Privacy
- [ ] Data Collection: Contact Info (email)
- [ ] Data Collection: Photos (receipt images)
- [ ] Data Collection: Financial Info (expense data)
- [ ] Data Usage: App Functionality
- [ ] Linked to user identity

#### App Review Information
- [ ] Add demo account (for Apple review)
- [ ] Add notes about Firebase/Camera usage
- [ ] Provide test subscription credentials

---

## Testing

### Pre-Production Testing
- [ ] TestFlight beta with 5+ testers
- [ ] Test all authentication flows
- [ ] Test receipt capture → processing → approval
- [ ] Test Free tier limit (21st receipt should fail)
- [ ] Test subscription purchase (sandbox)
- [ ] Test Pro features unlock after purchase
- [ ] Test export generation (PDF/CSV)
- [ ] Test share link (email to external user)
- [ ] Test account deletion (all data removed)

### Performance Testing
- [ ] App launches in < 3 seconds
- [ ] Receipt upload completes in < 10 seconds
- [ ] Receipt processing completes in < 30 seconds
- [ ] Export generation < 10 seconds for 100 receipts

### Security Testing
- [ ] Firestore rules block unauthorized access
- [ ] Storage rules block unauthorized access
- [ ] Cannot modify entitlements from client
- [ ] Share tokens not readable by client
- [ ] Transaction mapping not accessible

---

## Launch

### Submission
1. In App Store Connect → **Submit for Review**
2. Expected review time: 1-3 days
3. Monitor for rejection messages

### Post-Approval
- [ ] Release to App Store
- [ ] Monitor Crashlytics for errors
- [ ] Check Analytics for user behavior
- [ ] Monitor Firebase usage/costs

### Marketing (Optional)
- [ ] Update website with App Store link
- [ ] Share on social media
- [ ] Create demo video

---

## Monitoring

### Week 1
- [ ] Check daily crashlytics reports
- [ ] Monitor Cloud Functions logs
- [ ] Check Firebase Storage usage
- [ ] Review user feedback/reviews
- [ ] Track conversion rate (Free → Pro)

### Monthly
- [ ] Review Firebase costs
- [ ] Check LLM API usage/costs
- [ ] Monitor subscription churn
- [ ] Analyze receipt processing accuracy
- [ ] Review support requests

---

## Scaling

### If usage grows:
- [ ] Implement caching for category suggestions
- [ ] Optimize Cloud Functions (reduce cold starts)
- [ ] Add CDN for export downloads
- [ ] Consider batch processing for exports
- [ ] Monitor and increase rate limits

### Cost Optimization:
- [ ] Use Firestore indexes efficiently
- [ ] Implement aggressive LLM caching
- [ ] Use Storage lifecycle policies (delete old exports)
- [ ] Optimize image compression before upload

---

## Rollback Plan

If critical issues found:
1. Remove app from sale in App Store Connect
2. Roll back Cloud Functions: `firebase deploy --only functions`
3. Fix issues in development
4. Re-test thoroughly
5. Resubmit

---

## Success Metrics

### Launch Goals (Month 1)
- 100+ downloads
- 50+ active users
- 10+ Pro subscribers
- < 1% crash rate
- 4+ star average rating

### Growth Goals (Month 3)
- 1,000+ downloads
- 500+ active users
- 50+ Pro subscribers
- Receipt processing accuracy > 80%
- Positive reviews (10+)
