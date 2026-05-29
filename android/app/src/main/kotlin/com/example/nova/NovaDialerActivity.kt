package com.example.nova

import android.Manifest
import android.app.Activity
import android.app.AlertDialog
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.provider.CallLog
import android.provider.ContactsContract
import android.text.Editable
import android.text.TextUtils
import android.text.TextWatcher
import android.view.Gravity
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.CheckBox
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.PopupMenu
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NovaDialerActivity : Activity() {

    private data class ContactEntry(
        val name: String,
        val number: String,
        val normalizedNumber: String,
        val searchableName: String,
        val contactId: Long,
        val rawContactId: Long
    )

    private data class RecentCallEntry(
        val title: String,
        val subtitle: String,
        val number: String
    )

    private lateinit var titleView: TextView
    private lateinit var topBackButton: Button
    private lateinit var topMenuButton: Button
    private lateinit var numberField: EditText
    private lateinit var contactSearchField: EditText
    private lateinit var recentsTab: Button
    private lateinit var contactsTab: Button
    private lateinit var keypadTab: Button
    private lateinit var addContactButton: Button
    private lateinit var listHeader: TextView
    private lateinit var listScroll: View
    private lateinit var listContainer: LinearLayout
    private lateinit var keypadPanel: LinearLayout

    private val contactCache = mutableListOf<ContactEntry>()
    private val visibleContacts = mutableListOf<ContactEntry>()
    private var contactsLoadedForMatching = false
    private var suppressNumberWatcher = false
    private var suppressSearchWatcher = false
    private var activeTab: String = TAB_KEYPAD
    private var inContactDetail = false
    private var currentDetailContact: ContactEntry? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        NovaCallControlBridge.initialize(applicationContext)
        NovaPhoneControlBridge.initialize(applicationContext)
        setContentView(R.layout.activity_nova_dialer)
        bindViews()
        bindActions()
        seedIncomingNumber()
        val requestedTab = intent?.getStringExtra(EXTRA_INITIAL_TAB)
            ?: if (intent?.action == Intent.ACTION_DIAL && intent?.data != null) TAB_KEYPAD else TAB_RECENTS
        showTab(requestedTab)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        seedIncomingNumber()
        showTab(intent?.getStringExtra(EXTRA_INITIAL_TAB) ?: TAB_KEYPAD)
    }

    private fun bindViews() {
        titleView = findViewById(R.id.dialerTitle)
        topBackButton = findViewById(R.id.topBackButton)
        topMenuButton = findViewById(R.id.topMenuButton)
        numberField = findViewById(R.id.dialerNumberField)
        contactSearchField = findViewById(R.id.contactSearchField)
        recentsTab = findViewById(R.id.recentsShortcutButton)
        contactsTab = findViewById(R.id.contactsShortcutButton)
        keypadTab = findViewById(R.id.keypadShortcutButton)
        addContactButton = findViewById(R.id.addContactShortcutButton)
        listHeader = findViewById(R.id.listHeader)
        listScroll = findViewById(R.id.listScroll)
        listContainer = findViewById(R.id.listContainer)
        keypadPanel = findViewById(R.id.keypadPanel)
    }

    private fun bindActions() {
        recentsTab.setOnClickListener { showTab(TAB_RECENTS) }
        contactsTab.setOnClickListener { showTab(TAB_CONTACTS) }
        keypadTab.setOnClickListener { showTab(TAB_KEYPAD) }
        addContactButton.setOnClickListener { openAddContact() }
        topMenuButton.setOnClickListener { openTopMenu(it) }
        topBackButton.setOnClickListener {
            if (inContactDetail) showTab(TAB_CONTACTS) else finish()
        }

        val digits = listOf(
            R.id.dialerDigit1 to '1', R.id.dialerDigit2 to '2', R.id.dialerDigit3 to '3',
            R.id.dialerDigit4 to '4', R.id.dialerDigit5 to '5', R.id.dialerDigit6 to '6',
            R.id.dialerDigit7 to '7', R.id.dialerDigit8 to '8', R.id.dialerDigit9 to '9',
            R.id.dialerDigitStar to '*', R.id.dialerDigit0 to '0', R.id.dialerDigitHash to '#'
        )
        digits.forEach { (id, digit) ->
            findViewById<Button>(id).setOnClickListener {
                appendDigit(digit)
                showTab(TAB_KEYPAD, reload = false)
                updateKeypadMatches()
            }
        }

        findViewById<Button>(R.id.dialerDeleteButton).setOnClickListener {
            val text = numberField.text
            if (text.isNotEmpty()) text.delete(text.length - 1, text.length)
            updateKeypadMatches()
        }
        findViewById<Button>(R.id.dialerDeleteButton).setOnLongClickListener {
            numberField.text.clear()
            updateKeypadMatches()
            true
        }

        numberField.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                if (!suppressNumberWatcher && activeTab == TAB_KEYPAD) updateKeypadMatches()
            }
            override fun afterTextChanged(s: Editable?) = Unit
        })

        contactSearchField.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                if (!suppressSearchWatcher && activeTab == TAB_CONTACTS) loadContacts()
            }
            override fun afterTextChanged(s: Editable?) = Unit
        })

        findViewById<Button>(R.id.dialerCallButton).setOnClickListener { placeCallFromField() }
        findViewById<Button>(R.id.dialerCloseButton).setOnClickListener { finish() }
    }

    private fun seedIncomingNumber() {
        val incoming = intent?.data?.schemeSpecificPart.orEmpty()
        if (incoming.isNotBlank()) {
            suppressNumberWatcher = true
            numberField.setText(incoming)
            numberField.setSelection(numberField.text.length)
            suppressNumberWatcher = false
            updateKeypadMatches()
        }
    }

    private fun showTab(tab: String, reload: Boolean = true) {
        inContactDetail = false
        currentDetailContact = null
        topBackButton.visibility = View.GONE
        activeTab = when (tab) {
            TAB_RECENTS, TAB_CONTACTS, TAB_KEYPAD -> tab
            else -> TAB_KEYPAD
        }

        recentsTab.isSelected = activeTab == TAB_RECENTS
        contactsTab.isSelected = activeTab == TAB_CONTACTS
        keypadTab.isSelected = activeTab == TAB_KEYPAD

        titleView.text = when (activeTab) {
            TAB_CONTACTS -> "Kişiler"
            TAB_RECENTS -> "Son aramalar"
            else -> "Telefon"
        }

        keypadPanel.visibility = if (activeTab == TAB_KEYPAD) View.VISIBLE else View.GONE
        listScroll.visibility = if (activeTab == TAB_KEYPAD) View.GONE else View.VISIBLE
        listHeader.visibility = if (activeTab == TAB_KEYPAD) View.GONE else View.VISIBLE

        numberField.visibility = if (activeTab == TAB_KEYPAD) View.VISIBLE else View.GONE
        contactSearchField.visibility = if (activeTab == TAB_CONTACTS) View.VISIBLE else View.GONE
        addContactButton.visibility = if (activeTab == TAB_CONTACTS || activeTab == TAB_KEYPAD) View.VISIBLE else View.GONE
        topMenuButton.visibility = View.VISIBLE

        if (activeTab == TAB_KEYPAD) {
            numberField.requestFocus()
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
            imm?.hideSoftInputFromWindow(numberField.windowToken, 0)
            updateKeypadMatches()
        }

        if (reload) {
            when (activeTab) {
                TAB_RECENTS -> loadRecents()
                TAB_CONTACTS -> loadContacts()
            }
        }
    }

    private fun loadRecents() {
        listHeader.text = "Son aramalar"
        listContainer.removeAllViews()
        val recentCalls = queryRecentCalls(limit = 80)
        if (recentCalls == null) {
            addInfoRow("Arama geçmişi izni gerekli", "Ayarlar > Uygulamalar > NOVA > İzinler bölümünden Telefon/Arama geçmişi iznini açın.")
            return
        }
        if (recentCalls.isEmpty()) {
            addInfoRow("Arama kaydı yok", "Arama yaptığınızda veya çağrı geldiğinde burada görünecek.")
            return
        }
        recentCalls.forEach { addCallLogRow(it) }
    }

    private fun loadContacts() {
        val query = contactSearchField.text?.toString().orEmpty().trim()
        listHeader.text = if (query.isBlank()) "Kişiler" else "Kişiler • arama: $query"
        listContainer.removeAllViews()

        val contacts = queryContactEntries(limit = 1200)
        if (contacts == null) {
            visibleContacts.clear()
            addInfoRow("Kişiler izni gerekli", "Ayarlar > Uygulamalar > NOVA > İzinler bölümünden Kişiler iznini açın.")
            return
        }

        contactCache.clear()
        contactCache.addAll(contacts)
        contactsLoadedForMatching = true

        val filtered = filterContacts(contacts, query)
        visibleContacts.clear()
        visibleContacts.addAll(filtered)

        if (filtered.isEmpty()) {
            addInfoRow(if (query.isBlank()) "Kişi yok" else "Kişi bulunamadı", "İsme veya numaraya göre arama yapabilir, yeni kişi ekleyebilirsiniz.")
        } else {
            filtered.take(250).forEach { item -> addContactRow(item) }
        }
    }

    private fun filterContacts(source: List<ContactEntry>, query: String): List<ContactEntry> {
        if (query.isBlank()) return source
        val queryLower = query.lowercase(Locale("tr", "TR"))
        val queryDigits = normalizeNumber(query)
        return source.filter { item ->
            item.searchableName.contains(queryLower) ||
                item.normalizedNumber.contains(queryDigits) ||
                item.normalizedNumber.endsWith(queryDigits)
        }
    }

    private fun queryContactEntries(limit: Int): List<ContactEntry>? {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) return null

        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY,
            ContactsContract.CommonDataKinds.Phone.NUMBER,
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.RAW_CONTACT_ID
        )

        val cursor = runCatching {
            contentResolver.query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                projection,
                null,
                null,
                "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY} COLLATE LOCALIZED ASC"
            )
        }.getOrNull() ?: return emptyList()

        val prefs = policyPrefs()
        val result = mutableListOf<ContactEntry>()
        val seen = LinkedHashSet<String>()
        cursor.use {
            val nameIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME_PRIMARY)
            val numberIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
            val contactIdIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val rawContactIdIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.RAW_CONTACT_ID)
            while (it.moveToNext() && result.size < limit) {
                val rawName = if (nameIndex >= 0) it.getString(nameIndex).orEmpty() else ""
                val number = if (numberIndex >= 0) it.getString(numberIndex).orEmpty() else ""
                val normalized = normalizeNumber(number)
                if (number.isBlank() || normalized.isBlank()) continue
                val contactId = if (contactIdIndex >= 0) it.getLong(contactIdIndex) else -1L
                val rawContactId = if (rawContactIdIndex >= 0) it.getLong(rawContactIdIndex) else -1L
                val displayName = prefs.getString(policyKey(normalized, "displayNameOverride"), "")
                    ?.trim()
                    ?.takeIf { value -> value.isNotBlank() }
                    ?: rawName.ifBlank { number }
                val key = "${contactId.takeIf { id -> id > 0 } ?: displayName.trim()}|$normalized"
                if (!seen.add(key)) continue
                result += ContactEntry(
                    name = displayName,
                    number = number,
                    normalizedNumber = normalized,
                    searchableName = listOf(displayName, rawName, number, normalized)
                        .joinToString(" ")
                        .lowercase(Locale("tr", "TR")),
                    contactId = contactId,
                    rawContactId = rawContactId
                )
            }
        }
        return result
    }

    private fun queryRecentCalls(limit: Int): List<RecentCallEntry>? {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) return null
        val projection = arrayOf(
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION
        )
        val cursor = runCatching {
            contentResolver.query(CallLog.Calls.CONTENT_URI, projection, null, null, "${CallLog.Calls.DATE} DESC")
        }.getOrNull() ?: return emptyList()

        val result = mutableListOf<RecentCallEntry>()
        cursor.use {
            val nameIndex = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
            val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)
            val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
            val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
            while (it.moveToNext() && result.size < limit) {
                val name = if (nameIndex >= 0) it.getString(nameIndex).orEmpty() else ""
                val number = if (numberIndex >= 0) it.getString(numberIndex).orEmpty() else ""
                val type = if (typeIndex >= 0) it.getInt(typeIndex) else 0
                val date = if (dateIndex >= 0) it.getLong(dateIndex) else 0L
                val duration = if (durationIndex >= 0) it.getLong(durationIndex) else 0L
                result += RecentCallEntry(
                    title = name.ifBlank { number.ifBlank { "Bilinmeyen" } },
                    subtitle = "${callTypeLabel(type)} • ${dateLabel(date)}${if (duration > 0) " • ${duration}s" else ""}",
                    number = number
                )
            }
        }
        return result
    }

    private fun queryRecentCallsForNumber(number: String, limit: Int): List<RecentCallEntry>? {
        val target = normalizeNumber(number)
        if (target.isBlank()) return emptyList()
        val calls = queryRecentCalls(limit = 240) ?: return null
        return calls.filter { entry ->
            val normalized = normalizeNumber(entry.number)
            normalized.isNotBlank() && (
                normalized == target ||
                    normalized.endsWith(target.takeLast(10)) ||
                    target.endsWith(normalized.takeLast(10))
            )
        }.take(limit)
    }

    private fun ensureContactCacheForMatching() {
        if (contactsLoadedForMatching) return
        val contacts = queryContactEntries(limit = 1200) ?: emptyList()
        contactCache.clear()
        contactCache.addAll(contacts)
        contactsLoadedForMatching = true
    }

    private fun updateKeypadMatches() {
        if (activeTab != TAB_KEYPAD) return
        val raw = numberField.text?.toString().orEmpty().trim()
        val queryDigits = normalizeNumber(raw)
        if (queryDigits.length < 3) {
            listHeader.visibility = View.GONE
            listScroll.visibility = View.GONE
            return
        }

        ensureContactCacheForMatching()

        val normalizedText = raw.lowercase(Locale("tr", "TR"))
        val matches = contactCache.asSequence()
            .filter { item ->
                item.normalizedNumber.contains(queryDigits) ||
                    item.normalizedNumber.endsWith(queryDigits) ||
                    item.searchableName.contains(normalizedText)
            }
            .take(6)
            .toList()

        if (matches.isEmpty()) {
            listHeader.text = "Eşleşen kişi yok"
            listHeader.visibility = View.VISIBLE
            listScroll.visibility = View.GONE
            return
        }

        listHeader.text = "Eşleşen kişiler"
        listHeader.visibility = View.VISIBLE
        listScroll.visibility = View.VISIBLE
        listContainer.removeAllViews()
        matches.forEach { item -> addContactRow(item) }
    }

    private fun addCallLogRow(entry: RecentCallEntry) {
        addTwoLineRow(
            title = entry.title,
            subtitle = entry.subtitle,
            number = entry.number,
            fromCallLog = true,
            contactEntry = resolveContactEntry(entry.title, entry.number)
        )
    }

    private fun addContactRow(entry: ContactEntry) {
        val contactsListRow = activeTab == TAB_CONTACTS && !inContactDetail
        addTwoLineRow(
            title = entry.name.ifBlank { entry.number },
            subtitle = if (contactsListRow) entry.number else contactSubtitle(entry),
            number = entry.number,
            fromCallLog = false,
            contactEntry = entry,
            showInlineCallButton = !contactsListRow
        )
    }

    private fun addTwoLineRow(
        title: String,
        subtitle: String,
        number: String,
        fromCallLog: Boolean,
        contactEntry: ContactEntry?,
        showInlineCallButton: Boolean = true
    ) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_row)
            setPadding(dp(14), dp(14), dp(12), dp(14))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dp(8)
            }
        }

        val avatar = TextView(this).apply {
            text = title.firstOrNull { it.isLetterOrDigit() }?.uppercaseChar()?.toString() ?: "?"
            gravity = Gravity.CENTER
            textSize = 17f
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            setTextColor(0xFFFFFFFF.toInt())
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_caller_avatar)
        }
        row.addView(avatar, LinearLayout.LayoutParams(dp(46), dp(46)))

        val texts = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(12), 0, dp(8), 0)
        }
        texts.addView(TextView(this).apply {
            text = title
            textSize = 16f
            setSingleLine(true)
            ellipsize = TextUtils.TruncateAt.END
            setTextColor(0xFF2A0709.toInt())
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
        })
        texts.addView(TextView(this).apply {
            text = subtitle
            textSize = 12f
            setSingleLine(true)
            ellipsize = TextUtils.TruncateAt.END
            setTextColor(0xFF6A3E3A.toInt())
        })
        row.addView(texts, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))

        if (showInlineCallButton) {
            val callButton = Button(this).apply {
                text = "Ara"
                isAllCaps = false
                setTextColor(0xFFFFFFFF.toInt())
                background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_call_green)
                setOnClickListener {
                    suppressNumberWatcher = true
                    numberField.setText(number)
                    suppressNumberWatcher = false
                    placeCall(number)
                }
            }
            row.addView(callButton, LinearLayout.LayoutParams(dp(64), dp(44)))
        }

        row.setOnClickListener {
            if (fromCallLog) {
                openRecentCallActions(title, number)
            } else {
                openContactDetails(contactEntry ?: resolveContactEntry(title, number))
            }
        }
        listContainer.addView(row)
    }

    private fun openContactDetails(entry: ContactEntry?) {
        val contact = entry ?: return
        if (contact.normalizedNumber.isBlank()) return
        inContactDetail = true
        currentDetailContact = contact
        activeTab = TAB_CONTACTS

        recentsTab.isSelected = false
        contactsTab.isSelected = true
        keypadTab.isSelected = false
        topBackButton.visibility = View.VISIBLE
        topMenuButton.visibility = View.VISIBLE
        titleView.text = contact.name.ifBlank { contact.number }

        keypadPanel.visibility = View.GONE
        numberField.visibility = View.GONE
        contactSearchField.visibility = View.GONE
        addContactButton.visibility = View.GONE
        listHeader.visibility = View.GONE
        listScroll.visibility = View.VISIBLE
        listContainer.removeAllViews()

        addContactDetailHero(contact)
        addContactDetailActionButtons(contact)
        addContactDetailOptionRow("AI Otomatik Yanıtla", "Bu kişi için çağrı yanıtlama ve companion izinlerini yönet.") {
            openContactCustomization(contact)
        }
        addContactDetailOptionRow("Arama Özeti", "Bu kişiye ait Nova not ve özet tercihlerini düzenle.") {
            openContactCustomization(contact)
        }
        addContactDetailOptionRow("Arama Kayıtları", "Son çağrılar burada sadece bu kişiye göre gösterilir.") {
            toast("Bu kişinin arama günlüğü aşağıda gösteriliyor.")
        }

        addSectionHeader("Arama Günlüğü")
        val calls = queryRecentCallsForNumber(contact.number, limit = 12)
        when {
            calls == null -> addSmallInfoRow("Arama geçmişi izni gerekli", "Bu kişiye ait aramaları göstermek için Arama geçmişi izni gerekli.")
            calls.isEmpty() -> addSmallInfoRow("Bu kişiye ait son arama yok", "Bu kişiyle yapılan aramalar burada görünecek.")
            else -> calls.forEach { addCallLogRow(it) }
        }
    }

    private fun addContactDetailHero(entry: ContactEntry) {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_dialer_card)
            setPadding(dp(18), dp(18), dp(18), dp(18))
            layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = dp(10)
            }
        }
        box.addView(TextView(this).apply {
            text = entry.name.firstOrNull { it.isLetterOrDigit() }?.uppercaseChar()?.toString() ?: "?"
            gravity = Gravity.CENTER
            textSize = 30f
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            setTextColor(0xFFFFFFFF.toInt())
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_caller_avatar)
        }, LinearLayout.LayoutParams(dp(88), dp(88)))
        box.addView(TextView(this).apply {
            text = entry.name.ifBlank { entry.number }
            textSize = 22f
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            setTextColor(0xFF2A0709.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dp(12), 0, 0)
        })
        box.addView(TextView(this).apply {
            text = entry.number
            textSize = 13f
            setTextColor(0xFF6A3E3A.toInt())
            gravity = Gravity.CENTER
            setPadding(0, dp(4), 0, 0)
        })
        listContainer.addView(box)
    }

    private fun addContactDetailActionButtons(entry: ContactEntry) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(2), 0, dp(8))
        }
        fun actionButton(textValue: String, onClick: () -> Unit): Button = Button(this).apply {
            text = textValue
            isAllCaps = false
            textSize = 13f
            setTextColor(0xFF8A1116.toInt())
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_dialer_card)
            setOnClickListener { onClick() }
        }
        row.addView(actionButton("Ara") { placeCall(entry.number) }, LinearLayout.LayoutParams(0, dp(46), 1f).apply { rightMargin = dp(6) })
        row.addView(actionButton("Mesaj") { openSms(entry.number) }, LinearLayout.LayoutParams(0, dp(46), 1f).apply { leftMargin = dp(3); rightMargin = dp(3) })
        row.addView(actionButton("Özelleştir") { openContactCustomization(entry) }, LinearLayout.LayoutParams(0, dp(46), 1f).apply { leftMargin = dp(6) })
        listContainer.addView(row)
    }

    private fun addContactDetailOptionRow(title: String, subtitle: String, onClick: () -> Unit) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_row)
            setPadding(dp(14), dp(14), dp(12), dp(14))
            setOnClickListener { onClick() }
        }
        val texts = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        texts.addView(TextView(this).apply {
            text = title
            textSize = 15f
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            setTextColor(0xFF2A0709.toInt())
        })
        texts.addView(TextView(this).apply {
            text = subtitle
            textSize = 12f
            setSingleLine(true)
            ellipsize = TextUtils.TruncateAt.END
            setTextColor(0xFF6A3E3A.toInt())
        })
        row.addView(texts, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        row.addView(TextView(this).apply {
            text = "›"
            textSize = 24f
            setTextColor(0xFF8A1116.toInt())
        })
        listContainer.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = dp(8)
        })
    }

    private fun openSms(number: String) {
        if (number.isBlank()) return
        val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:${Uri.encode(number)}"))
        runCatching { startActivity(intent) }.onFailure { toast("Mesaj uygulaması açılamadı.") }
    }

    private fun openContactCustomization(entry: ContactEntry?) {
        if (entry == null || entry.normalizedNumber.isBlank()) return
        val prefs = policyPrefs()
        fun key(field: String): String = policyKey(entry.normalizedNumber, field)

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(8), dp(18), dp(4))
        }

        fun label(textValue: String) {
            container.addView(TextView(this).apply {
                text = textValue
                textSize = 13f
                setTypeface(Typeface.DEFAULT, Typeface.BOLD)
                setTextColor(0xFF2A0709.toInt())
                setPadding(0, dp(8), 0, dp(2))
            })
        }

        fun editor(labelText: String, field: String, hintText: String, max: Int = 3): EditText {
            label(labelText)
            val edit = EditText(this).apply {
                setText(prefs.getString(key(field), "") ?: "")
                hint = hintText
                minLines = 1
                maxLines = max
                setTextColor(0xFF2A0709.toInt())
                setHintTextColor(0xFF8A6A61.toInt())
            }
            container.addView(edit)
            return edit
        }

        val displayName = editor(
            "Bu kişi Nova telefonunda hangi isimle görünsün?",
            "displayNameOverride",
            entry.name.ifBlank { entry.number },
            max = 1
        )
        if (displayName.text.isNullOrBlank()) displayName.setText(entry.name)

        val profileEnabled = CheckBox(this).apply {
            text = "Bu kişiyi Nova çağrı profiline dahil et"
            isChecked = prefs.getBoolean(key("profileEnabled"), false)
        }
        val callAnswerAllowed = CheckBox(this).apply {
            text = "Nova bu kişi aradığında çağrı yanıtlamayı kullanabilir"
            isChecked = prefs.getBoolean(key("callAnswerAllowed"), false)
        }
        val companionAllowed = CheckBox(this).apply {
            text = "Bu kişiyle companion konuşmasına izin ver"
            isChecked = prefs.getBoolean(key("companionAllowed"), false)
        }
        val takeNotes = CheckBox(this).apply {
            text = "Görüşme notu alınabilir"
            isChecked = prefs.getBoolean(key("takeNotes"), false)
        }
        val preferSpeaker = CheckBox(this).apply {
            text = "Mümkünse hoparlör tercih edilsin"
            isChecked = prefs.getBoolean(key("preferSpeaker"), false)
        }
        fun syncChecks() {
            val enabled = profileEnabled.isChecked
            callAnswerAllowed.isEnabled = enabled
            companionAllowed.isEnabled = enabled
            takeNotes.isEnabled = enabled
            preferSpeaker.isEnabled = enabled
        }
        profileEnabled.setOnCheckedChangeListener { _, _ -> syncChecks() }
        container.addView(profileEnabled)
        container.addView(callAnswerAllowed)
        container.addView(companionAllowed)
        container.addView(takeNotes)
        container.addView(preferSpeaker)
        syncChecks()

        val greeting = editor("Nova bu kişi arayınca nasıl karşılasın?", "greeting", "Örn: Sakin, kısa ve samimi karşıla.")
        val expected = editor("Bu kişi genelde ne sorabilir?", "expected", "Örn: Ne zaman döneceğimi sorabilir.")
        val allowed = editor("Nova hangi konularda cevap verebilir?", "allowed", "Örn: Sadece meşgul olduğumu belirt.")
        val forbidden = editor("Nova neye girmesin?", "forbidden", "Örn: özel bilgiler, konum, planlar.")
        val emergency = editor("Acil durumda ne yapsın?", "emergency", "Örn: 2 kez üst üste ararsa beni uyarsın.")
        val quickReply = editor("Kapat ve yanıtla hazır mesajı", "quickReply", "Örn: Şu an müsait değilim, birazdan döneceğim.")

        AlertDialog.Builder(this)
            .setTitle(entry.name)
            .setMessage(entry.number)
            .setView(container)
            .setNegativeButton("Vazgeç", null)
            .setNeutralButton("Kişiyi sil") { _, _ -> confirmDeleteContacts(listOf(entry)) }
            .setPositiveButton("Kaydet") { _, _ ->
                val enabled = profileEnabled.isChecked
                val newDisplayName = displayName.text?.toString()?.trim().orEmpty()
                prefs.edit()
                    .putString(key("displayNameOverride"), newDisplayName)
                    .putString(key("name"), newDisplayName.ifBlank { entry.name })
                    .putString(key("number"), entry.number)
                    .putBoolean(key("profileEnabled"), enabled)
                    .putBoolean(key("callAnswerAllowed"), enabled && callAnswerAllowed.isChecked)
                    .putBoolean(key("companionAllowed"), enabled && companionAllowed.isChecked)
                    .putBoolean(key("takeNotes"), enabled && takeNotes.isChecked)
                    .putBoolean(key("preferSpeaker"), enabled && preferSpeaker.isChecked)
                    .putString(key("greeting"), greeting.text?.toString().orEmpty())
                    .putString(key("expected"), expected.text?.toString().orEmpty())
                    .putString(key("allowed"), allowed.text?.toString().orEmpty())
                    .putString(key("forbidden"), forbidden.text?.toString().orEmpty())
                    .putString(key("emergency"), emergency.text?.toString().orEmpty())
                    .putString(key("quickReply"), quickReply.text?.toString().orEmpty())
                    .apply()
                if (newDisplayName.isNotBlank() && newDisplayName != entry.name) renameContact(entry, newDisplayName)
                contactsLoadedForMatching = false
                val refreshed = resolveContactEntry(newDisplayName.ifBlank { entry.name }, entry.number) ?: entry.copy(name = newDisplayName.ifBlank { entry.name })
                if (inContactDetail) openContactDetails(refreshed) else if (activeTab == TAB_CONTACTS) loadContacts()
            }
            .show()
    }

    private fun openRecentCallActions(title: String, number: String) {
        if (number.isBlank()) return
        val contactEntry = resolveContactEntry(title, number)
        val actions = arrayOf("Ara", "Kişi detayını aç", "Kişiyi / numarayı özelleştir", "Yeni kişi olarak ekle", "Tuş takımına al")
        AlertDialog.Builder(this)
            .setTitle(title)
            .setMessage(number)
            .setItems(actions) { _, which ->
                when (which) {
                    0 -> placeCall(number)
                    1 -> openContactDetails(contactEntry)
                    2 -> openContactCustomization(contactEntry)
                    3 -> openAddContactWithNumber(number)
                    4 -> {
                        suppressNumberWatcher = true
                        numberField.setText(number)
                        numberField.setSelection(numberField.text.length)
                        suppressNumberWatcher = false
                        showTab(TAB_KEYPAD, reload = false)
                    }
                }
            }
            .show()
    }

    private fun openTopMenu(anchor: View) {
        val menu = PopupMenu(this, anchor)
        when {
            inContactDetail -> {
                menu.menu.add(0, MENU_EDIT_CONTACT, 0, "Kişiyi düzenle / özelleştir")
                menu.menu.add(0, MENU_CONTACT_TO_KEYPAD, 1, "Tuş takımına al")
                menu.menu.add(0, MENU_DELETE_CURRENT, 2, "Kişiyi sil")
            }
            activeTab == TAB_CONTACTS -> {
                menu.menu.add(0, MENU_ADD_CONTACT, 0, "Yeni kişi ekle")
                if (contactSearchField.text?.toString()?.isNotBlank() == true && visibleContacts.isNotEmpty()) {
                    menu.menu.add(0, MENU_DELETE_FILTERED, 1, "Filtrelenen kişileri toplu sil")
                }
            }
            activeTab == TAB_RECENTS -> {
                menu.menu.add(0, MENU_CLEAR_RECENTS, 0, "Son aramaları temizle")
                menu.menu.add(0, MENU_OPEN_KEYPAD, 1, "Tuş takımını aç")
            }
            else -> {
                menu.menu.add(0, MENU_ADD_CONTACT, 0, "Yeni kişi olarak ekle")
                menu.menu.add(0, MENU_DELETE_CURRENT, 1, "Seçili numaradaki kişiyi sil")
            }
        }
        menu.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                MENU_ADD_CONTACT -> {
                    openAddContact()
                    true
                }
                MENU_EDIT_CONTACT -> {
                    openContactCustomization(currentDetailContact)
                    true
                }
                MENU_CONTACT_TO_KEYPAD -> {
                    val entry = currentDetailContact
                    if (entry == null) {
                        toast("Tuş takımına alınacak kişi yok.")
                    } else {
                        suppressNumberWatcher = true
                        numberField.setText(entry.number)
                        numberField.setSelection(numberField.text.length)
                        suppressNumberWatcher = false
                        showTab(TAB_KEYPAD, reload = false)
                    }
                    true
                }
                MENU_OPEN_KEYPAD -> {
                    showTab(TAB_KEYPAD)
                    true
                }
                MENU_DELETE_CURRENT -> {
                    val match = currentDetailContact ?: run {
                        val normalized = normalizeNumber(numberField.text?.toString().orEmpty())
                        contactCache.firstOrNull { it.normalizedNumber == normalized }
                            ?: visibleContacts.firstOrNull { it.normalizedNumber == normalized }
                    }
                    if (match == null) toast("Silinecek kişi için önce numara veya kişi seçin.") else confirmDeleteContacts(listOf(match))
                    true
                }
                MENU_DELETE_FILTERED -> {
                    if (activeTab != TAB_CONTACTS) showTab(TAB_CONTACTS)
                    if (visibleContacts.isEmpty()) toast("Toplu silme için görünür kişi yok.") else confirmDeleteContacts(visibleContacts.toList())
                    true
                }
                MENU_CLEAR_RECENTS -> {
                    confirmClearRecents()
                    true
                }
                else -> false
            }
        }
        menu.show()
    }

    private fun addSectionHeader(textValue: String) {
        listContainer.addView(TextView(this).apply {
            text = textValue
            textSize = 14f
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            setTextColor(0xFF8A1116.toInt())
            setPadding(dp(4), dp(16), dp(4), dp(8))
        })
    }

    private fun addInfoRow(title: String, subtitle: String) {
        val box = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_dialer_card)
            setPadding(dp(20), dp(28), dp(20), dp(28))
        }
        box.addView(TextView(this).apply {
            text = title
            textSize = 17f
            setTypeface(Typeface.DEFAULT, Typeface.BOLD)
            gravity = Gravity.CENTER
            setTextColor(0xFF2A0709.toInt())
        })
        box.addView(TextView(this).apply {
            text = subtitle
            textSize = 13f
            gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, 0)
            setTextColor(0xFF6A3E3A.toInt())
        })
        listContainer.addView(box, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
    }

    private fun addSmallInfoRow(title: String, subtitle: String) {
        val row = TextView(this).apply {
            text = "$title\n$subtitle"
            textSize = 13f
            setTextColor(0xFF6A3E3A.toInt())
            setPadding(dp(12), dp(12), dp(12), dp(12))
            background = ContextCompat.getDrawable(this@NovaDialerActivity, R.drawable.bg_system_dialer_card)
        }
        listContainer.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
            bottomMargin = dp(8)
        })
    }

    private fun openAddContact() {
        openAddContactWithNumber(numberField.text?.toString()?.trim().orEmpty())
    }

    private fun openAddContactWithNumber(number: String) {
        val intent = Intent(ContactsContract.Intents.Insert.ACTION).apply {
            type = ContactsContract.RawContacts.CONTENT_TYPE
            if (number.isNotBlank()) putExtra(ContactsContract.Intents.Insert.PHONE, number)
        }
        runCatching { startActivity(intent) }
    }

    private fun appendDigit(digit: Char) {
        numberField.visibility = View.VISIBLE
        numberField.text.append(digit.toString())
        numberField.setSelection(numberField.text.length)
    }

    private fun placeCallFromField() {
        placeCall(numberField.text?.toString().orEmpty())
    }

    private fun placeCall(raw: String) {
        val number = raw.trim()
        if (number.isBlank()) return
        NovaCallAuthorityGuard.registerUserCallAction("dial")
        NovaCarrierBoundaryGuard.registerManualOutbound(number)
        NovaPhoneControlBridge.executeStep("place_call", number, 0)
    }

    private fun confirmDeleteContacts(entries: List<ContactEntry>) {
        val unique = entries.filter { it.contactId > 0 || it.rawContactId > 0 }.distinctBy { it.normalizedNumber }
        if (unique.isEmpty()) {
            toast("Silinebilecek kişi kaydı bulunamadı.")
            return
        }
        AlertDialog.Builder(this)
            .setTitle(if (unique.size == 1) "Kişiyi sil" else "${unique.size} kişiyi sil")
            .setMessage("Bu işlem telefon rehberinden siler. Devam edilsin mi?")
            .setNegativeButton("Vazgeç", null)
            .setPositiveButton("Sil") { _, _ ->
                var deleted = 0
                unique.forEach { if (deleteContact(it)) deleted++ }
                toast("Silinen kişi: $deleted")
                contactsLoadedForMatching = false
                if (inContactDetail) showTab(TAB_CONTACTS) else if (activeTab == TAB_CONTACTS) loadContacts()
            }
            .show()
    }

    private fun deleteContact(entry: ContactEntry): Boolean {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            toast("Kişi silmek için Kişiler yazma izni gerekli.")
            return false
        }
        val deleted = runCatching {
            when {
                entry.rawContactId > 0 -> contentResolver.delete(
                    ContactsContract.RawContacts.CONTENT_URI,
                    "${ContactsContract.RawContacts._ID}=?",
                    arrayOf(entry.rawContactId.toString())
                )
                entry.contactId > 0 -> contentResolver.delete(
                    ContactsContract.RawContacts.CONTENT_URI,
                    "${ContactsContract.RawContacts.CONTACT_ID}=?",
                    arrayOf(entry.contactId.toString())
                )
                else -> 0
            }
        }.getOrDefault(0)
        return deleted > 0
    }

    private fun renameContact(entry: ContactEntry, newName: String) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            toast("İsim Nova içinde kaydedildi. Telefon rehberine yazmak için Kişiler yazma izni gerekli.")
            return
        }
        if (entry.rawContactId <= 0L) return
        val values = ContentValues().apply {
            put(ContactsContract.CommonDataKinds.StructuredName.DISPLAY_NAME, newName)
            put(ContactsContract.CommonDataKinds.StructuredName.GIVEN_NAME, newName)
        }
        val updated = runCatching {
            contentResolver.update(
                ContactsContract.Data.CONTENT_URI,
                values,
                "${ContactsContract.Data.RAW_CONTACT_ID}=? AND ${ContactsContract.Data.MIMETYPE}=?",
                arrayOf(entry.rawContactId.toString(), ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
            )
        }.getOrDefault(0)
        if (updated <= 0) {
            runCatching {
                val insertValues = ContentValues(values).apply {
                    put(ContactsContract.Data.RAW_CONTACT_ID, entry.rawContactId)
                    put(ContactsContract.Data.MIMETYPE, ContactsContract.CommonDataKinds.StructuredName.CONTENT_ITEM_TYPE)
                }
                contentResolver.insert(ContactsContract.Data.CONTENT_URI, insertValues)
            }
        }
    }

    private fun confirmClearRecents() {
        AlertDialog.Builder(this)
            .setTitle("Son aramaları temizle")
            .setMessage("Nova telefon ekranındaki arama geçmişi temizlenecek. Devam edilsin mi?")
            .setNegativeButton("Vazgeç", null)
            .setPositiveButton("Temizle") { _, _ -> clearRecents() }
            .show()
    }

    private fun clearRecents() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            toast("Son aramaları temizlemek için Arama kaydı yazma izni gerekli.")
            return
        }
        val deleted = runCatching { contentResolver.delete(CallLog.Calls.CONTENT_URI, null, null) }.getOrDefault(0)
        toast("Temizlenen arama kaydı: $deleted")
        if (activeTab == TAB_RECENTS) loadRecents()
    }

    private fun resolveContactEntry(title: String, number: String): ContactEntry? {
        ensureContactCacheForMatching()
        val normalized = normalizeNumber(number)
        if (normalized.isBlank()) return null
        return contactCache.firstOrNull { it.normalizedNumber == normalized }
            ?: ContactEntry(
                name = title.ifBlank { number },
                number = number,
                normalizedNumber = normalized,
                searchableName = "$title $number $normalized".lowercase(Locale("tr", "TR")),
                contactId = -1L,
                rawContactId = -1L
            )
    }

    private fun contactSubtitle(entry: ContactEntry): String {
        val prefs = policyPrefs()
        val normalized = entry.normalizedNumber
        val managed = prefs.getBoolean(policyKey(normalized, "profileEnabled"), false)
        if (!managed) return "${entry.number} • Nova profili kapalı"
        val tags = mutableListOf<String>()
        if (prefs.getBoolean(policyKey(normalized, "callAnswerAllowed"), false)) tags += "çağrı yanıt"
        if (prefs.getBoolean(policyKey(normalized, "companionAllowed"), false)) tags += "companion"
        if (tags.isEmpty()) tags += "seçili, izin yok"
        return "${entry.number} • ${tags.joinToString(" + ")}"
    }

    private fun callTypeLabel(type: Int): String = when (type) {
        CallLog.Calls.INCOMING_TYPE -> "Gelen"
        CallLog.Calls.OUTGOING_TYPE -> "Giden"
        CallLog.Calls.MISSED_TYPE -> "Cevapsız"
        CallLog.Calls.REJECTED_TYPE -> "Reddedildi"
        CallLog.Calls.BLOCKED_TYPE -> "Engellendi"
        else -> "Arama"
    }

    private fun dateLabel(date: Long): String {
        if (date <= 0L) return ""
        return SimpleDateFormat("dd MMM HH:mm", Locale("tr", "TR")).format(Date(date))
    }

    private fun normalizeNumber(number: String): String = number.filter { it.isDigit() || it == '+' }

    private fun policyPrefs() = getSharedPreferences(PREF_CONTACT_CALL_POLICY, Context.MODE_PRIVATE)

    private fun policyKey(normalizedNumber: String, field: String): String = "$normalizedNumber.$field"

    private fun toast(message: String) = Toast.makeText(this, message, Toast.LENGTH_SHORT).show()

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        const val EXTRA_INITIAL_TAB = "nova.extra.INITIAL_DIALER_TAB"
        const val TAB_RECENTS = "recents"
        const val TAB_CONTACTS = "contacts"
        const val TAB_KEYPAD = "keypad"
        private const val PREF_CONTACT_CALL_POLICY = "nova_contact_call_policy_v1"
        private const val MENU_ADD_CONTACT = 10
        private const val MENU_DELETE_CURRENT = 11
        private const val MENU_DELETE_FILTERED = 12
        private const val MENU_CLEAR_RECENTS = 13
        private const val MENU_EDIT_CONTACT = 14
        private const val MENU_CONTACT_TO_KEYPAD = 15
        private const val MENU_OPEN_KEYPAD = 16

        fun contactsIntent(context: Context): Intent =
            Intent(context, NovaDialerActivity::class.java).putExtra(EXTRA_INITIAL_TAB, TAB_CONTACTS)

        fun recentsIntent(context: Context): Intent =
            Intent(context, NovaDialerActivity::class.java).putExtra(EXTRA_INITIAL_TAB, TAB_RECENTS)

        fun keypadIntent(context: Context): Intent =
            Intent(context, NovaDialerActivity::class.java).putExtra(EXTRA_INITIAL_TAB, TAB_KEYPAD)
    }
}
