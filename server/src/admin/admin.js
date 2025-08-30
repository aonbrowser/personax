// Admin Panel JavaScript
const API_URL = '/v1/admin';

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
    try {
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
            const errorText = await response.text();
            console.error('API Error Response:', errorText);
            throw new Error(`API Error: ${response.status} - ${errorText}`);
        }
        
        return response.json();
    } catch (error) {
        console.error('API Request failed:', endpoint, error);
        throw error;
    }
}

// Pricing Functions
async function loadPricingData() {
    try {
        // Load subscription plans
        const plansData = await apiRequest('/pricing/plans');
        const plans = plansData.plans || [];
        
        plans.forEach(plan => {
            if (plan.id === 'free') {
                document.getElementById('free_analysis_count').value = plan.total_analysis_credits || 0;
                document.getElementById('free_coaching').value = plan.coaching_tokens_limit / 1000;
                document.getElementById('free_price').value = 0;
            } else if (plan.id === 'standard') {
                document.getElementById('standard_analysis_count').value = plan.total_analysis_credits || 0;
                document.getElementById('standard_coaching').value = plan.coaching_tokens_limit / 1000;
                document.getElementById('standard_price').value = plan.price_usd;
            } else if (plan.id === 'extra') {
                document.getElementById('extra_analysis_count').value = plan.total_analysis_credits || 0;
                document.getElementById('extra_coaching').value = plan.coaching_tokens_limit / 1000;
                document.getElementById('extra_price').value = plan.price_usd;
            }
        });
        
        // Load PAYG pricing - but don't display anything (keeping for token package prices)
        const paygData = await apiRequest('/pricing/payg');
        const paygPricing = paygData.pricing || [];
        
        const paygContainer = document.getElementById('paygPricing');
        // Clear the container - we'll only show token packages below
        paygContainer.innerHTML = '';
        
        // Load token packages
        const tokenData = await apiRequest('/token-packages');
        const tokenPackages = tokenData.packages || [];
        
        tokenPackages.forEach(pkg => {
            const input = document.getElementById(pkg.id);
            if (input) {
                input.value = pkg.price_usd;
                input.setAttribute('data-package-id', pkg.id);
            }
        });
    } catch (error) {
        console.error('Error loading pricing data:', error);
        alert('Fiyat verileri yüklenemedi!');
    }
}

async function savePlans() {
    try {
        // Save free plan
        const freeAnalysisCount = parseInt(document.getElementById('free_analysis_count').value) || 0;
        const freeData = {
            total_analysis_credits: freeAnalysisCount,
            coaching_tokens_limit: parseInt(document.getElementById('free_coaching').value || 0) * 1000,
            price_usd: 0
        };
        console.log('Saving free plan:', freeData);
        await apiRequest('/pricing/plans/free', {
            method: 'PUT',
            body: JSON.stringify(freeData)
        });
        
        // Save standard plan
        const standardAnalysisCount = parseInt(document.getElementById('standard_analysis_count').value) || 0;
        const standardData = {
            total_analysis_credits: standardAnalysisCount,
            coaching_tokens_limit: parseInt(document.getElementById('standard_coaching').value || 0) * 1000,
            price_usd: parseFloat(document.getElementById('standard_price').value)
        };
        console.log('Saving standard plan:', standardData);
        await apiRequest('/pricing/plans/standard', {
            method: 'PUT',
            body: JSON.stringify(standardData)
        });
        
        // Save extra plan
        const extraAnalysisCount = parseInt(document.getElementById('extra_analysis_count').value) || 0;
        const extraData = {
            total_analysis_credits: extraAnalysisCount,
            coaching_tokens_limit: parseInt(document.getElementById('extra_coaching').value || 0) * 1000,
            price_usd: parseFloat(document.getElementById('extra_price').value)
        };
        console.log('Saving extra plan:', extraData);
        await apiRequest('/pricing/plans/extra', {
            method: 'PUT',
            body: JSON.stringify(extraData)
        });
        
        alert('Abonelik paketleri başarıyla güncellendi!');
        // Reload data to show updated values
        await loadPricingData();
    } catch (error) {
        console.error('Error saving plans:', error);
        alert('Paketler kaydedilirken hata oluştu: ' + error.message);
    }
}

async function savePayg() {
    try {
        // Save token packages
        const tokenPackages = document.querySelectorAll('.token-package-input');
        for (const input of tokenPackages) {
            const packageId = input.getAttribute('data-package-id') || input.id;
            const price = parseFloat(input.value);
            
            if (!isNaN(price) && price >= 0) {
                await apiRequest(`/token-packages/${packageId}`, {
                    method: 'PUT',
                    body: JSON.stringify({
                        price_usd: price
                    })
                });
            }
        }
        
        alert('Token paketleri başarıyla güncellendi!');
        // Reload data to show updated values
        await loadPricingData();
    } catch (error) {
        console.error('Error saving token packages:', error);
        alert('Token paketleri kaydedilirken hata oluştu: ' + error.message);
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