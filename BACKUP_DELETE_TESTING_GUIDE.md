# Backup Delete Feature - Testing Guide

## 🧪 Comprehensive Testing Instructions

### Prerequisites
- ✅ Flutter development environment set up
- ✅ Android device or emulator running
- ✅ Google account for testing
- ✅ Internet connection available

---

## 📋 Test Cases

### Test Case 1: Basic Delete Functionality
**Objective**: Verify that users can successfully delete a backup

**Steps**:
1. Open the app
2. Navigate to Settings → Backup & Restore
3. Connect to Google Drive (if not connected)
4. Create at least 2 backups using "Backup Now"
5. Locate a backup in the Restore section
6. Tap the trash icon (🗑️) next to the backup
7. Verify confirmation dialog appears
8. Tap "Delete" button
9. Wait for operation to complete

**Expected Results**:
- ✅ Trash icon appears next to each backup
- ✅ Confirmation dialog shows correct backup details
- ✅ Dialog displays: date, device name, size
- ✅ Warning message: "This action cannot be undone"
- ✅ Success message appears: "Backup deleted successfully"
- ✅ Backup list refreshes automatically
- ✅ Deleted backup no longer appears in list
- ✅ Backup is removed from Google Drive

---

### Test Case 2: Cancel Deletion
**Objective**: Verify that users can cancel deletion

**Steps**:
1. Navigate to Backup & Restore screen
2. Tap trash icon on any backup
3. Confirmation dialog appears
4. Tap "Cancel" button

**Expected Results**:
- ✅ Dialog closes
- ✅ Backup is NOT deleted
- ✅ Backup still appears in list
- ✅ No success/error message shown

---

### Test Case 3: Delete Multiple Backups
**Objective**: Verify sequential deletion works correctly

**Steps**:
1. Create 3 or more backups
2. Delete first backup (confirm)
3. Wait for success message
4. Delete second backup (confirm)
5. Wait for success message
6. Verify remaining backups

**Expected Results**:
- ✅ Each deletion completes successfully
- ✅ List refreshes after each deletion
- ✅ Correct backups remain
- ✅ No duplicate entries
- ✅ No crashes or freezes

---

### Test Case 4: Delete Last Backup
**Objective**: Verify behavior when deleting the only backup

**Steps**:
1. Ensure only 1 backup exists
2. Delete the backup
3. Confirm deletion

**Expected Results**:
- ✅ Backup deletes successfully
- ✅ "No backups available" message appears
- ✅ Refresh button is shown
- ✅ No errors occur

---

### Test Case 5: Network Error Handling
**Objective**: Verify graceful handling of network issues

**Steps**:
1. Navigate to Backup & Restore
2. Turn off WiFi/Mobile data
3. Tap trash icon on a backup
4. Confirm deletion
5. Wait for error

**Expected Results**:
- ✅ Error message appears
- ✅ Message is user-friendly (not technical)
- ✅ Backup remains in list
- ✅ App doesn't crash
- ✅ User can retry after reconnecting

**Example Error Messages**:
- "Failed to delete backup: No internet connection"
- "Failed to delete backup: Network error"

---

### Test Case 6: Authentication Error
**Objective**: Verify handling of expired authentication

**Steps**:
1. Connect to Google Drive
2. Wait for token to expire (or revoke manually)
3. Attempt to delete a backup
4. Observe error handling

**Expected Results**:
- ✅ Error message about authentication
- ✅ Suggests reconnecting account
- ✅ App doesn't crash
- ✅ User can reconnect and retry

---

### Test Case 7: UI Responsiveness
**Objective**: Verify UI remains responsive during deletion

**Steps**:
1. Start deleting a backup
2. Observe UI during operation
3. Try interacting with other elements

**Expected Results**:
- ✅ Loading indicator shown (if applicable)
- ✅ UI doesn't freeze
- ✅ Other buttons remain accessible
- ✅ User can navigate away if needed

---

### Test Case 8: Visual Design Verification
**Objective**: Verify UI matches design specifications

**Steps**:
1. Navigate to Backup & Restore
2. Examine backup list items
3. Check button colors and layout
4. Open confirmation dialog
5. Verify dialog design

**Expected Results**:
- ✅ Delete button uses error color (red/brown)
- ✅ Restore button uses primary color (blue)
- ✅ Buttons are properly spaced
- ✅ Touch targets are large enough (48x48dp)
- ✅ Dialog is centered and readable
- ✅ Text is clear and legible
- ✅ Warning text is emphasized

---

### Test Case 9: Accessibility Testing
**Objective**: Verify accessibility features work correctly

**Steps**:
1. Enable TalkBack/Screen Reader
2. Navigate to backup list
3. Focus on delete button
4. Activate delete button
5. Navigate confirmation dialog

**Expected Results**:
- ✅ Delete button announces "Delete"
- ✅ Restore button announces "Restore"
- ✅ Dialog content is readable
- ✅ Buttons are focusable
- ✅ Navigation is logical

---

### Test Case 10: Rapid Tap Prevention
**Objective**: Verify protection against rapid tapping

**Steps**:
1. Tap delete button
2. Immediately tap delete button again multiple times
3. Confirm deletion
4. Observe behavior

**Expected Results**:
- ✅ Only one dialog opens
- ✅ Only one deletion occurs
- ✅ No duplicate operations
- ✅ No crashes

---

## 🔍 Edge Cases

### Edge Case 1: Very Large Backup
**Test**: Delete a backup > 50MB
**Expected**: Deletion completes successfully, may take longer

### Edge Case 2: Very Old Backup
**Test**: Delete a backup from months ago
**Expected**: Deletion works regardless of age

### Edge Case 3: Backup with Special Characters
**Test**: Delete backup with special chars in device name
**Expected**: Dialog displays correctly, deletion succeeds

### Edge Case 4: Simultaneous Operations
**Test**: Start backup while deleting another
**Expected**: Both operations complete independently

### Edge Case 5: Low Storage on Device
**Test**: Delete backup when device storage is low
**Expected**: Deletion succeeds (only affects Drive)

---

## 📱 Device Testing Matrix

### Android Versions
- [ ] Android 14 (API 34)
- [ ] Android 13 (API 33)
- [ ] Android 12 (API 31)
- [ ] Android 11 (API 30)
- [ ] Android 10 (API 29)

### Screen Sizes
- [ ] Small (< 5 inches)
- [ ] Medium (5-6 inches)
- [ ] Large (6-7 inches)
- [ ] Tablet (> 7 inches)

### Orientations
- [ ] Portrait mode
- [ ] Landscape mode

---

## 🎯 Performance Testing

### Test 1: Deletion Speed
**Measure**: Time from confirm to success message
**Target**: < 3 seconds on good connection
**Acceptable**: < 10 seconds on slow connection

### Test 2: UI Responsiveness
**Measure**: Frame rate during deletion
**Target**: 60 FPS maintained
**Acceptable**: No visible lag or stuttering

### Test 3: Memory Usage
**Measure**: Memory consumption during deletion
**Target**: No memory leaks
**Acceptable**: Memory returns to baseline after operation

---

## 🔐 Security Testing

### Test 1: Authorization
**Verify**: Only authenticated users can delete
**Expected**: Unauthenticated requests fail gracefully

### Test 2: Scope Limitation
**Verify**: Can only delete own backups
**Expected**: Cannot access other users' backups

### Test 3: Drive Permissions
**Verify**: Uses correct Drive scope
**Expected**: Only accesses appDataFolder

---

## 📊 Test Results Template

```
Test Date: _______________
Tester: _______________
Device: _______________
Android Version: _______________

Test Case 1: Basic Delete Functionality
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 2: Cancel Deletion
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 3: Delete Multiple Backups
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 4: Delete Last Backup
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 5: Network Error Handling
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 6: Authentication Error
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 7: UI Responsiveness
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 8: Visual Design Verification
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 9: Accessibility Testing
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Test Case 10: Rapid Tap Prevention
Status: [ ] Pass [ ] Fail
Notes: _________________________________

Overall Result: [ ] All Pass [ ] Some Failures
Critical Issues: _________________________________
Minor Issues: _________________________________
Recommendations: _________________________________
```

---

## 🐛 Bug Reporting Template

```
Bug Title: _________________________________

Severity: [ ] Critical [ ] High [ ] Medium [ ] Low

Steps to Reproduce:
1. _________________________________
2. _________________________________
3. _________________________________

Expected Behavior:
_________________________________

Actual Behavior:
_________________________________

Screenshots/Logs:
_________________________________

Device Information:
- Device: _________________________________
- Android Version: _________________________________
- App Version: _________________________________

Additional Notes:
_________________________________
```

---

## ✅ Acceptance Criteria

The feature is ready for release when:

- [ ] All test cases pass
- [ ] No critical bugs found
- [ ] UI matches design specifications
- [ ] Accessibility requirements met
- [ ] Performance targets achieved
- [ ] Error handling works correctly
- [ ] Documentation is complete
- [ ] Code review approved
- [ ] Build succeeds without warnings

---

## 🚀 Quick Test Script

For rapid testing, run this sequence:

```bash
# 1. Build and install
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk

# 2. Launch app
adb shell am start -n com.carevault.patient_app/.MainActivity

# 3. Test sequence
# - Navigate to Backup & Restore
# - Connect Google Drive
# - Create 2 backups
# - Delete 1 backup
# - Verify success
# - Check Drive to confirm deletion

# 4. Check logs
adb logcat | grep -i "backup\|delete\|error"
```

---

## 📞 Support Contacts

**For Testing Issues**:
- Developer: [Your Name]
- QA Lead: [QA Name]
- Project Manager: [PM Name]

**For Google Drive API Issues**:
- Google Cloud Console: https://console.cloud.google.com
- API Documentation: https://developers.google.com/drive

---

## 📝 Testing Checklist Summary

### Pre-Testing
- [ ] Development environment ready
- [ ] Test device/emulator available
- [ ] Google account configured
- [ ] Internet connection stable

### Functional Testing
- [ ] Basic delete works
- [ ] Cancel works
- [ ] Multiple deletes work
- [ ] Last backup delete works

### Error Testing
- [ ] Network errors handled
- [ ] Auth errors handled
- [ ] API errors handled

### UI/UX Testing
- [ ] Visual design correct
- [ ] Accessibility works
- [ ] Responsive on all screens

### Performance Testing
- [ ] Deletion speed acceptable
- [ ] No memory leaks
- [ ] UI remains responsive

### Final Verification
- [ ] All tests passed
- [ ] Documentation complete
- [ ] Ready for release

---

## 🎉 Testing Complete!

Once all tests pass, the feature is ready for production deployment.

**Next Steps**:
1. ✅ Complete all test cases
2. ✅ Document any issues found
3. ✅ Fix critical bugs
4. ✅ Retest after fixes
5. ✅ Get final approval
6. ✅ Deploy to production

**Good luck with testing! 🚀**
