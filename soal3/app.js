const accounts = [
    { code: "", name: "-- Pilih Akun --" },
    { code: "110-10", name: "Kas Kecil (Petty Cash)" },
    { code: "110-20", name: "Bank BCA" },
    { code: "110-21", name: "Bank Mandiri" },
    { code: "510-10", name: "Beban Listrik" },
    { code: "510-11", name: "Beban Air" },
    { code: "510-12", name: "Beban Telepon & Internet" },
    { code: "510-20", name: "Beban Sewa Kantor" },
    { code: "510-30", name: "Beban Perlengkapan (Supplies)" },
    { code: "210-10", name: "Hutang Usaha (Accounts Payable)" }
];

const currencyFormatter = new Intl.NumberFormat("id-ID", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
});

document.addEventListener("DOMContentLoaded", () => {
    const journalBody = document.getElementById("journalBody");
    const addRowBtn = document.getElementById("addRowBtn");
    const totalDebitDisplay = document.getElementById("totalDebitDisplay");
    const totalCreditDisplay = document.getElementById("totalCreditDisplay");
    const differenceDisplay = document.getElementById("differenceDisplay");
    const differenceContainer = document.getElementById("differenceContainer");
    const statusIndicator = document.getElementById("statusIndicator");
    const submitBtn = document.getElementById("submitBtn");
    const draftBtn = document.getElementById("draftBtn");
    const resetBtn = document.getElementById("resetBtn");
    const validationMessage = document.getElementById("validationMessage");
    const validationText = document.getElementById("validationText");
    const inputTrxDate = document.getElementById("trxDate");
    const inputPayee = document.getElementById("payee");
    const inputDesc = document.getElementById("description");
    const confirmModal = document.getElementById("confirmModal");
    const messageModal = document.getElementById("messageModal");
    const voucherForm = document.getElementById("voucherForm");

    let rowCount = 0;
    let totalDebitCents = 0;
    let totalCreditCents = 0;
    let isValidForSubmit = false;

    function localDateString(date) {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, "0");
        const day = String(date.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    function formatCents(cents) {
        return currencyFormatter.format(cents / 100);
    }

    function amountToCents(rawValue) {
        if (rawValue.trim() === "") {
            return 0;
        }

        const amount = Number(rawValue);
        if (!Number.isFinite(amount) || !Number.isSafeInteger(Math.round(amount * 100))) {
            return null;
        }

        return Math.round(amount * 100);
    }

    function addJournalRow() {
        rowCount += 1;
        const row = document.createElement("tr");
        row.className = "hover:bg-slate-50 transition-colors journal-row";
        row.innerHTML = `
            <td class="px-4 py-2 text-center text-slate-400 row-number"></td>
            <td class="px-4 py-2">
                <select class="w-full rounded border border-slate-300 px-2 py-1.5 text-sm focus:ring-1 focus:ring-blue-500 bg-white acc-select" aria-label="Akun jurnal" required></select>
            </td>
            <td class="px-4 py-2">
                <input type="text" placeholder="Catatan baris (opsional)" class="w-full rounded border border-slate-300 px-2 py-1.5 text-sm focus:ring-1 focus:ring-blue-500 desc-input" aria-label="Keterangan baris">
            </td>
            <td class="px-4 py-2">
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-2 text-slate-400 text-xs">Rp</span>
                    <input type="number" min="0" step="0.01" class="w-full rounded border border-slate-300 pl-7 pr-2 py-1.5 text-sm text-right focus:ring-1 focus:ring-blue-500 debit-input" placeholder="0" aria-label="Debit">
                </div>
            </td>
            <td class="px-4 py-2">
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 flex items-center pl-2 text-slate-400 text-xs">Rp</span>
                    <input type="number" min="0" step="0.01" class="w-full rounded border border-slate-300 pl-7 pr-2 py-1.5 text-sm text-right focus:ring-1 focus:ring-blue-500 credit-input" placeholder="0" aria-label="Kredit">
                </div>
            </td>
            <td class="px-4 py-2 text-center">
                <button type="button" class="text-red-400 hover:text-red-600 transition-colors p-1 del-row-btn" title="Hapus Baris" aria-label="Hapus baris jurnal">
                    <i class="fas fa-trash-alt"></i>
                </button>
            </td>
        `;

        const accountSelect = row.querySelector(".acc-select");
        accounts.forEach((account) => {
            const option = document.createElement("option");
            option.value = account.code;
            option.textContent = account.code
                ? `${account.code} - ${account.name}`
                : account.name;
            accountSelect.appendChild(option);
        });

        journalBody.appendChild(row);
        updateRowNumbers();
        validateJournal();
    }

    function updateRowNumbers() {
        journalBody.querySelectorAll(".journal-row").forEach((row, index) => {
            row.querySelector(".row-number").textContent = String(index + 1);
        });
    }

    function updateSubmitButton(isEnabled) {
        submitBtn.disabled = !isEnabled;
        submitBtn.classList.toggle("bg-blue-600", isEnabled);
        submitBtn.classList.toggle("hover:bg-blue-700", isEnabled);
        submitBtn.classList.toggle("shadow-md", isEnabled);
        submitBtn.classList.toggle("transform", isEnabled);
        submitBtn.classList.toggle("hover:-translate-y-0.5", isEnabled);
        submitBtn.classList.toggle("bg-slate-300", !isEnabled);
        submitBtn.classList.toggle("text-slate-500", !isEnabled);
        submitBtn.classList.toggle("cursor-not-allowed", !isEnabled);
        submitBtn.classList.toggle("shadow-sm", !isEnabled);
        submitBtn.title = isEnabled
            ? "Buka konfirmasi simulasi submit"
            : "Jurnal harus seimbang dan valid sebelum submit";
    }

    function showMessage(title, text, type = "info") {
        const iconDiv = document.getElementById("messageIcon");
        document.getElementById("messageTitle").textContent = title;
        document.getElementById("messageText").textContent = text;

        if (type === "success") {
            iconDiv.className = "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100 mb-4";
            iconDiv.innerHTML = '<i class="fas fa-check text-xl text-green-600"></i>';
        } else if (type === "warning" || type === "error") {
            iconDiv.className = "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100 mb-4";
            iconDiv.innerHTML = '<i class="fas fa-exclamation-triangle text-xl text-red-600"></i>';
        } else {
            iconDiv.className = "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-blue-100 mb-4";
            iconDiv.innerHTML = '<i class="fas fa-info text-xl text-blue-600"></i>';
        }

        messageModal.classList.remove("hidden");
    }

    function validateJournal() {
        const errors = [];
        totalDebitCents = 0;
        totalCreditCents = 0;

        if (!inputTrxDate.value) {
            errors.push("Tanggal transaksi belum diisi.");
        }
        if (!inputPayee.value.trim()) {
            errors.push("Penerima pembayaran belum diisi.");
        }
        if (!inputDesc.value.trim()) {
            errors.push("Deskripsi transaksi belum diisi.");
        }

        let validRowCount = 0;
        let hasEmptyAccount = false;
        let hasNegativeAmount = false;
        let hasInvalidAmount = false;
        let hasBothSides = false;

        journalBody.querySelectorAll(".journal-row").forEach((row) => {
            const account = row.querySelector(".acc-select").value;
            const debitInput = row.querySelector(".debit-input");
            const creditInput = row.querySelector(".credit-input");
            const debitCents = amountToCents(debitInput.value);
            const creditCents = amountToCents(creditInput.value);

            if (debitCents === null || creditCents === null
                || debitInput.validity.badInput || creditInput.validity.badInput
                || debitInput.validity.stepMismatch || creditInput.validity.stepMismatch) {
                hasInvalidAmount = true;
                return;
            }

            if (debitCents < 0 || creditCents < 0) {
                hasNegativeAmount = true;
            }

            totalDebitCents += debitCents;
            totalCreditCents += creditCents;

            const hasDebit = debitCents > 0;
            const hasCredit = creditCents > 0;
            if (hasDebit && hasCredit) {
                hasBothSides = true;
            }

            if (hasDebit || hasCredit) {
                if (!account) {
                    hasEmptyAccount = true;
                } else if (!(hasDebit && hasCredit) && debitCents >= 0 && creditCents >= 0) {
                    validRowCount += 1;
                }
            }
        });

        if (hasInvalidAmount) {
            errors.push("Nominal harus berupa angka yang valid dengan maksimal dua angka desimal.");
        }
        if (hasNegativeAmount) {
            errors.push("Nominal jurnal tidak boleh bernilai negatif.");
        }
        if (hasEmptyAccount) {
            errors.push("Baris dengan nominal harus memiliki akun yang dipilih.");
        }
        if (hasBothSides) {
            errors.push("Setiap baris hanya boleh berisi Debit atau Kredit, bukan keduanya.");
        }

        const differenceCents = Math.abs(totalDebitCents - totalCreditCents);
        if (totalDebitCents === 0 && totalCreditCents === 0) {
            errors.push("Total Debit dan Kredit tidak boleh sama-sama nol.");
        } else if (differenceCents > 0) {
            errors.push(`Jurnal tidak seimbang. Selisih: Rp ${formatCents(differenceCents)}`);
        }
        if (validRowCount < 2) {
            errors.push("Minimal 2 baris jurnal harus diisi akun dan nominal yang valid.");
        }

        totalDebitDisplay.textContent = formatCents(totalDebitCents);
        totalCreditDisplay.textContent = formatCents(totalCreditCents);
        differenceDisplay.textContent = formatCents(differenceCents);

        const isBalanced = differenceCents === 0
            && totalDebitCents > 0
            && totalCreditCents > 0
            && errors.length === 0;

        if (isBalanced) {
            statusIndicator.className = "px-3 py-1 rounded-full text-sm font-semibold border-2 transition-all duration-300 border-green-500 text-green-600 bg-green-50";
            statusIndicator.innerHTML = '<i class="fas fa-check-circle mr-1"></i> BALANCED';
            differenceContainer.className = "px-4 py-2 text-center font-bold text-green-600 tracking-wider bg-green-50";
        } else {
            statusIndicator.className = "px-3 py-1 rounded-full text-sm font-semibold border-2 transition-all duration-300 border-red-500 text-red-500 bg-red-50";
            statusIndicator.innerHTML = '<i class="fas fa-times-circle mr-1"></i> UNBALANCED';
            differenceContainer.className = "px-4 py-2 text-center font-bold text-red-500 tracking-wider bg-red-50";
        }

        isValidForSubmit = errors.length === 0 && isBalanced;
        updateSubmitButton(isValidForSubmit);
        validationMessage.classList.toggle("hidden", isValidForSubmit);
        if (!isValidForSubmit) {
            validationText.textContent = errors[0] || "Jurnal harus valid dan seimbang.";
        }

        return isValidForSubmit;
    }

    function resetForm() {
        inputTrxDate.value = localDateString(new Date());
        inputPayee.value = "";
        inputDesc.value = "";
        journalBody.innerHTML = "";
        rowCount = 0;
        addJournalRow();
        addJournalRow();
        validateJournal();
        showMessage("Form Di-reset", "Formulir telah dikembalikan ke kondisi awal yang kosong.", "info");
    }

    function saveDraft() {
        draftBtn.disabled = true;
        draftBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-1"></i> Menyimpan simulasi...';

        window.setTimeout(() => {
            draftBtn.disabled = false;
            draftBtn.textContent = "Simpan Draft";
            showMessage(
                "Simulasi Draft Selesai",
                "Ini hanya simulasi di browser. Data draft belum disimpan ke database.",
                "info"
            );
        }, 500);
    }

    function submitData() {
        confirmModal.classList.add("hidden");
        if (!validateJournal()) {
            showMessage("Jurnal Belum Valid", "Perbaiki data jurnal sebelum mencoba simulasi Submit.", "warning");
            return;
        }

        showMessage(
            "Simulasi Submit Selesai",
            "Validasi di browser berhasil. Data tidak dikirim atau disimpan ke database dan voucher belum berstatus POSTED.",
            "info"
        );
    }

    inputTrxDate.value = localDateString(new Date());
    addJournalRow();
    addJournalRow();

    addRowBtn.addEventListener("click", addJournalRow);
    inputTrxDate.addEventListener("input", validateJournal);
    inputPayee.addEventListener("input", validateJournal);
    inputDesc.addEventListener("input", validateJournal);

    journalBody.addEventListener("input", (event) => {
        const target = event.target;
        if (!(target instanceof HTMLInputElement)) {
            return;
        }

        const row = target.closest(".journal-row");
        if (target.classList.contains("debit-input") && Number(target.value) > 0) {
            row.querySelector(".credit-input").value = "";
        } else if (target.classList.contains("credit-input") && Number(target.value) > 0) {
            row.querySelector(".debit-input").value = "";
        }
        validateJournal();
    });
    journalBody.addEventListener("change", validateJournal);
    journalBody.addEventListener("click", (event) => {
        const deleteButton = event.target.closest(".del-row-btn");
        if (!deleteButton) {
            return;
        }

        if (journalBody.querySelectorAll(".journal-row").length <= 2) {
            showMessage("Peringatan", "Sistem mengunci minimal 2 baris jurnal.", "warning");
            return;
        }

        deleteButton.closest(".journal-row").remove();
        updateRowNumbers();
        validateJournal();
    });

    resetBtn.addEventListener("click", resetForm);
    draftBtn.addEventListener("click", saveDraft);
    submitBtn.addEventListener("click", () => {
        if (validateJournal()) {
            confirmModal.classList.remove("hidden");
        }
    });
    document.getElementById("cancelSubmitBtn").addEventListener("click", () => {
        confirmModal.classList.add("hidden");
    });
    document.getElementById("confirmSubmitBtn").addEventListener("click", submitData);
    document.getElementById("closeMessageBtn").addEventListener("click", () => {
        messageModal.classList.add("hidden");
    });

    voucherForm.addEventListener("submit", (event) => {
        event.preventDefault();
        validateJournal();
    });
});
