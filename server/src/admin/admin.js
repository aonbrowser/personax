// Admin Panel JavaScript
const API_URL = 'http://localhost:8080/v1/admin';

// Authentication
let authToken = null;

// Check session on load
window.addEventListener('DOMContentLoaded', () => {
    checkSession();
    setupEventListeners();
});

function checkSession() {
    const session = localStorage.getItem('adminSession');
    if (session) {
        const { token, expiresAt, username } = JSON.parse(session);
        if (new Date().getTime() < expiresAt) {
            authToken = token;
            showAdminPanel(username);
            loadInitialData();
        } else {
            localStorage.removeItem('adminSession');
            showLogin();
        }
    } else {
        showLogin();
    }
}

function setupEventListeners() {
    // Login form
    document.getElementById('loginForm').addEventListener('submit', handleLogin);
    
    // Logout button
    document.getElementById('logoutBtn').addEventListener('click', handleLogout);
    
    // Navigation tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.addEventListener('click', (e) => {
            switchTab(e.target.dataset.tab);
        });
    });
}

async function handleLogin(e) {
    e.preventDefault();
    
    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;
    const errorDiv = document.getElementById('loginError');
    
    // Check credentials
    if (username === 'Capitano' && password === 'Mr.Capitano78') {
        // Generate token (simple for now)
        const token = btoa(`${username}:${Date.now()}`);
        const expiresAt = new Date().getTime() + (60 * 60 * 1000); // 1 hour
        
        // Save session
        localStorage.setItem('adminSession', JSON.stringify({
            token,
            expiresAt,
            username
        }));
        
        authToken = token;
        errorDiv.textContent = '';
        showAdminPanel(username);
        loadInitialData();
    } else {
        errorDiv.textContent = 'Hatalı kullanıcı adı veya şifre!';
    }
}

function handleLogout() {
    localStorage.removeItem('adminSession');
    authToken = null;
    showLogin();
}

function showLogin() {
    document.getElementById('loginContainer').style.display = 'flex';
    document.getElementById('adminPanel').style.display = 'none';
}

function showAdminPanel(username) {
    document.getElementById('loginContainer').style.display = 'none';
    document.getElementById('adminPanel').style.display = 'block';
    document.getElementById('adminUser').textContent = `👤 ${username}`;
}

function switchTab(tabName) {
    // Update nav tabs
    document.querySelectorAll('.nav-tab').forEach(tab => {
        tab.classList.toggle('active', tab.dataset.tab === tabName);
    });
    
    // Update content tabs
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.toggle('active', content.id === `${tabName}Tab`);
    });
    
    // Load tab data
    switch(tabName) {
        case 'pricing':
            loadPricingData();
            break;
        case 'usage':
            loadUsageStats();
            break;
        case 'prompts':
            loadPrompts();
            break;
        case 'dashboard':
            loadDashboard();
            break;
    }
}

async function loadInitialData() {
    loadPricingData();
}

// API Functions
async function apiRequest(endpoint, options = {}) {
    const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            'x-admin-key': 'admin-secret-key-2025',
            'x-admin-token': authToken,
            ...options.headers
        }
    });
    
    if (!response.ok) {
        throw new Error(`API Error: ${response.status}`);
    }
    
    return response.json();
}

// Pricing Functions
async function loadPricingData() {
    try {
        // Load subscription plans
        const plansData = await apiRequest('/pricing/plans');
        const plans = plansData.plans || [];
        
        plans.forEach(plan => {
            if (plan.id === 'standard') {
                document.getElementById('standard_self_reanalysis').value = plan.self_reanalysis_limit;
                document.getElementById('standard_other_analysis').value = plan.other_analysis_limit;
                document.getElementById('standard_relationship').value = plan.relationship_analysis_limit;
                document.getElementById('standard_coaching').value = plan.coaching_tokens_limit / 1000;
                document.getElementById('standard_price').value = plan.price_usd;
            } else if (plan.id === 'extra') {
                document.getElementById('extra_self_reanalysis').value = plan.self_reanalysis_limit;
                document.getElementById('extra_other_analysis').value = plan.other_analysis_limit;
                document.getElementById('extra_relationship').value = plan.relationship_analysis_limit;
                document.getElementById('extra_coaching').value = plan.coaching_tokens_limit / 1000;
                document.getElementById('extra_price').value = plan.price_usd;
            }
        });
        
        // Load PAYG pricing
        const paygData = await apiRequest('/pricing/payg');
        const paygPricing = paygData.pricing || [];
        
        const paygContainer = document.getElementById('paygPricing');
        paygContainer.innerHTML = paygPricing.map(item => `
            <div class="payg-item">
                <label>${getServiceTypeName(item.service_type)}</label>
                <div class="payg-price">
                    <span>$</span>
                    <input type="number" step="0.01" value="${item.price_usd}" 
                           data-id="${item.id}" class="input-number payg-input">
                </div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Error loading pricing data:', error);
        alert('Fiyat verileri yüklenemedi!');
    }
}

async function savePlans() {
    try {
        // Save standard plan
        await apiRequest('/pricing/plans/standard', {
            method: 'PUT',
            body: JSON.stringify({
                self_reanalysis_limit: parseInt(document.getElementById('standard_self_reanalysis').value),
                other_analysis_limit: parseInt(document.getElementById('standard_other_analysis').value),
                relationship_analysis_limit: parseInt(document.getElementById('standard_relationship').value),
                coaching_tokens_limit: parseInt(document.getElementById('standard_coaching').value) * 1000,
                price_usd: parseFloat(document.getElementById('standard_price').value)
            })
        });
        
        // Save extra plan
        await apiRequest('/pricing/plans/extra', {
            method: 'PUT',
            body: JSON.stringify({
                self_reanalysis_limit: parseInt(document.getElementById('extra_self_reanalysis').value),
                other_analysis_limit: parseInt(document.getElementById('extra_other_analysis').value),
                relationship_analysis_limit: parseInt(document.getElementById('extra_relationship').value),
                coaching_tokens_limit: parseInt(document.getElementById('extra_coaching').value) * 1000,
                price_usd: parseFloat(document.getElementById('extra_price').value)
            })
        });
        
        alert('Abonelik paketleri başarıyla güncellendi!');
    } catch (error) {
        console.error('Error saving plans:', error);
        alert('Paketler kaydedilirken hata oluştu!');
    }
}

async function savePayg() {
    try {
        const inputs = document.querySelectorAll('.payg-input');
        
        for (const input of inputs) {
            await apiRequest(`/pricing/payg/${input.dataset.id}`, {
                method: 'PUT',
                body: JSON.stringify({
                    price_usd: parseFloat(input.value)
                })
            });
        }
        
        alert('PAYG fiyatları başarıyla güncellendi!');
    } catch (error) {
        console.error('Error saving PAYG pricing:', error);
        alert('PAYG fiyatları kaydedilirken hata oluştu!');
    }
}

// Usage Stats Functions
async function loadUsageStats() {
    try {
        const userId = document.getElementById('userFilter').value;
        const month = document.getElementById('monthFilter').value;
        
        let query = '';
        if (userId) query += `?user_id=${userId}`;
        if (month) query += `${query ? '&' : '?'}month=${month}`;
        
        const data = await apiRequest(`/usage/stats${query}`);
        const stats = data.stats || [];
        
        const container = document.getElementById('usageStats');
        container.innerHTML = stats.map(stat => `
            <div class="stat-card">
                <h4>${stat.email || stat.user_id} - ${stat.month_year}</h4>
                <div>Plan: ${stat.plan_name || 'PAYG'}</div>
                <div>Kendi Analizi: ${stat.self_analysis_count}</div>
                <div>Tekrar Analiz: ${stat.self_reanalysis_count}</div>
                <div>Başka Kişi: ${stat.other_analysis_count}</div>
                <div>İlişki: ${stat.relationship_analysis_count}</div>
                <div>Coaching Token: ${stat.coaching_tokens_used}</div>
                <div>Toplam Ücret: $${stat.total_charged_usd}</div>
            </div>
        `).join('');
    } catch (error) {
        console.error('Error loading usage stats:', error);
        alert('Kullanım istatistikleri yüklenemedi!');
    }
}

// Prompts Functions
async function loadPrompts() {
    try {
        // Load prompt files
        const prompts = ['self', 'other', 'dyad', 'coach'];
        
        for (const promptType of prompts) {
            const response = await fetch(`/admin/prompts/${promptType}.md`);
            if (response.ok) {
                const content = await response.text();
                const textarea = document.getElementById(`prompt${promptType.charAt(0).toUpperCase() + promptType.slice(1)}`);
                if (textarea) {
                    textarea.value = content;
                }
            }
        }
    } catch (error) {
        console.error('Error loading prompts:', error);
    }
}

async function savePrompt(promptType) {
    try {
        const textarea = document.getElementById(`prompt${promptType.charAt(0).toUpperCase() + promptType.slice(1)}`);
        const content = textarea.value;
        
        const response = await fetch(`/admin/prompts/${promptType}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'text/plain',
                'x-admin-token': authToken
            },
            body: content
        });
        
        if (response.ok) {
            alert(`${promptType}.md başarıyla güncellendi!`);
        } else {
            throw new Error('Save failed');
        }
    } catch (error) {
        console.error('Error saving prompt:', error);
        alert('Prompt kaydedilirken hata oluştu!');
    }
}

// Dashboard Functions
async function loadDashboard() {
    try {
        const data = await apiRequest('/dashboard');
        const dashboard = data.dashboard;
        
        const container = document.getElementById('dashboardStats');
        container.innerHTML = `
            <div class="dashboard-card">
                <h3>Toplam Kullanıcı</h3>
                <div class="dashboard-value">${dashboard.totalUsers}</div>
            </div>
            <div class="dashboard-card">
                <h3>Aktif Abonelikler</h3>
                <div class="dashboard-value">
                    ${dashboard.activeSubscriptions.reduce((sum, s) => sum + parseInt(s.count), 0)}
                </div>
                <div class="dashboard-subtitle">
                    ${dashboard.activeSubscriptions.map(s => `${s.plan_id}: ${s.count}`).join(', ')}
                </div>
            </div>
            <div class="dashboard-card">
                <h3>Aylık Gelir</h3>
                <div class="dashboard-value">$${dashboard.monthlyRevenue.toFixed(2)}</div>
                <div class="dashboard-subtitle">${dashboard.currentMonth}</div>
            </div>
            <div class="dashboard-card">
                <h3>Aylık Maliyet</h3>
                <div class="dashboard-value">$${dashboard.monthlyCost.toFixed(2)}</div>
                <div class="dashboard-subtitle">OpenAI API</div>
            </div>
        `;
        
        // Add top users table
        if (dashboard.topUsers && dashboard.topUsers.length > 0) {
            container.innerHTML += `
                <div class="section" style="grid-column: 1/-1;">
                    <h3>En Çok Kullananlar</h3>
                    <table class="data-table">
                        <thead>
                            <tr>
                                <th>Email</th>
                                <th>Toplam Analiz</th>
                                <th>Coaching Token</th>
                                <th>Ücret</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${dashboard.topUsers.map(user => `
                                <tr>
                                    <td>${user.email}</td>
                                    <td>${user.total_analyses}</td>
                                    <td>${user.coaching_tokens_used}</td>
                                    <td>$${user.total_charged_usd}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }
    } catch (error) {
        console.error('Error loading dashboard:', error);
        alert('Dashboard verileri yüklenemedi!');
    }
}

// Helper Functions
function getServiceTypeName(type) {
    const names = {
        'self_analysis': 'Kendi Analizim',
        'self_reanalysis': 'Kendi Tekrar Analizim',
        'new_person': 'Yeni Kişi Analizi',
        'same_person_reanalysis': 'Aynı Kişinin Tekrar Analizi',
        'relationship': 'İlişki Analizi',
        'relationship_reanalysis': 'Aynı İlişkinin Tekrar Analizi',
        'coaching_100k': '100.000 Token Paketi',
        'coaching_500k': '500.000 Token Paketi'
    };
    return names[type] || type;
}