// CalendarAI Frontend Application
class CalendarAI {
    constructor() {
        this.currentTab = 'dashboard';
        this.mockData = this.generateMockData();
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.startRealTimeUpdates();
        this.animateStatsCards();
        console.log('CalendarAI Dashboard Initialized');
    }

    setupEventListeners() {
        // Tab navigation
        document.querySelectorAll('.nav-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab);
            });
        });

        // Action buttons
        document.querySelectorAll('.btn, .btn-sm').forEach(button => {
            button.addEventListener('click', (e) => {
                this.handleButtonClick(e);
            });
        });

        // Demo features
        this.setupDemoFeatures();
    }

    switchTab(tabName) {
        // Update active tab
        document.querySelectorAll('.nav-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        this.currentTab = tabName;
        this.showTabContent(tabName);
    }

    showTabContent(tabName) {
        const main = document.querySelector('.main');
        
        switch(tabName) {
            case 'dashboard':
                this.showDashboard();
                break;
            case 'properties':
                this.showPropertyCalendar();
                break;
            case 'emails':
                this.showEmailAnalysis();
                break;
            case 'settings':
                this.showSettings();
                break;
        }
    }

    showDashboard() {
        // Dashboard is already shown, just refresh data
        this.updateDashboardData();
        this.showNotification('Dashboard refreshed', 'success');
    }

    showPropertyCalendar() {
        const main = document.querySelector('.main .container');
        main.innerHTML = `
            <div class="property-calendar-view">
                <div class="calendar-header">
                    <h2><i class="fas fa-calendar-alt"></i> Property Calendar</h2>
                    <p>View all property-related events, inspections, and deadlines</p>
                </div>
                
                <div class="calendar-filters">
                    <button class="filter-btn active" data-filter="all">All Events</button>
                    <button class="filter-btn" data-filter="inspections">Inspections</button>
                    <button class="filter-btn" data-filter="work-orders">Work Orders</button>
                    <button class="filter-btn" data-filter="certifications">Certifications</button>
                </div>

                <div class="calendar-grid">
                    ${this.generateCalendarView()}
                </div>

                <div class="upcoming-events">
                    <h3>Next 7 Days</h3>
                    ${this.generateUpcomingEvents()}
                </div>
            </div>
        `;
        this.setupCalendarEvents();
    }

    showEmailAnalysis() {
        const main = document.querySelector('.main .container');
        main.innerHTML = `
            <div class="email-analysis-view">
                <div class="analysis-header">
                    <h2><i class="fas fa-robot"></i> AI Email Analysis</h2>
                    <p>Smart extraction of property information from emails</p>
                </div>

                <div class="analysis-stats">
                    <div class="stat-box">
                        <div class="stat-number">247</div>
                        <div class="stat-label">Emails Processed</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number">89%</div>
                        <div class="stat-label">Extraction Accuracy</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number">156</div>
                        <div class="stat-label">Tasks Created</div>
                    </div>
                    <div class="stat-box">
                        <div class="stat-number">23</div>
                        <div class="stat-label">Critical Alerts</div>
                    </div>
                </div>

                <div class="email-processing">
                    <h3>Recent Email Analysis</h3>
                    ${this.generateEmailAnalysis()}
                </div>

                <div class="ai-insights">
                    <h3>AI Insights</h3>
                    ${this.generateAIInsights()}
                </div>
            </div>
        `;
    }

    showSettings() {
        const main = document.querySelector('.main .container');
        main.innerHTML = `
            <div class="settings-view">
                <div class="settings-header">
                    <h2><i class="fas fa-cog"></i> Settings</h2>
                    <p>Configure your CalendarAI system</p>
                </div>

                <div class="settings-grid">
                    <div class="settings-card">
                        <h3><i class="fas fa-envelope"></i> Gmail Integration</h3>
                        <div class="setting-item">
                            <label>Gmail Account Status</label>
                            <div class="status-indicator connected">Connected</div>
                        </div>
                        <div class="setting-item">
                            <label>Auto-sync Interval</label>
                            <select>
                                <option>Every 5 minutes</option>
                                <option>Every 15 minutes</option>
                                <option>Every hour</option>
                            </select>
                        </div>
                        <button class="btn">Reconnect Gmail</button>
                    </div>

                    <div class="settings-card">
                        <h3><i class="fas fa-brain"></i> AI Configuration</h3>
                        <div class="setting-item">
                            <label>AI Analysis Confidence</label>
                            <input type="range" min="0" max="100" value="85">
                            <span>85%</span>
                        </div>
                        <div class="setting-item">
                            <label>Auto-create Tasks</label>
                            <input type="checkbox" checked>
                        </div>
                        <button class="btn">Update AI Settings</button>
                    </div>

                    <div class="settings-card">
                        <h3><i class="fas fa-bell"></i> Notifications</h3>
                        <div class="setting-item">
                            <label>Critical Alerts</label>
                            <input type="checkbox" checked>
                        </div>
                        <div class="setting-item">
                            <label>Daily Summary</label>
                            <input type="checkbox" checked>
                        </div>
                        <div class="setting-item">
                            <label>Email Notifications</label>
                            <input type="checkbox">
                        </div>
                        <button class="btn">Save Preferences</button>
                    </div>
                </div>
            </div>
        `;
    }

    generateCalendarView() {
        const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        const today = new Date();
        const calendar = [];

        // Generate a simple calendar grid
        for (let week = 0; week < 5; week++) {
            calendar.push('<div class="calendar-week">');
            for (let day = 0; day < 7; day++) {
                const date = new Date(today);
                date.setDate(today.getDate() + (week * 7) + day - today.getDay());
                
                const events = this.getEventsForDate(date);
                const isToday = date.toDateString() === today.toDateString();
                
                calendar.push(`
                    <div class="calendar-day ${isToday ? 'today' : ''}" data-date="${date.toISOString()}">
                        <div class="day-header">
                            <span class="day-name">${days[day]}</span>
                            <span class="day-number">${date.getDate()}</span>
                        </div>
                        <div class="day-events">
                            ${events.map(event => `
                                <div class="event ${event.type}">
                                    <span class="event-time">${event.time}</span>
                                    <span class="event-title">${event.title}</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `);
            }
            calendar.push('</div>');
        }

        return calendar.join('');
    }

    getEventsForDate(date) {
        // Mock events for demo
        const events = [];
        const random = Math.floor(Math.random() * 3);
        
        if (random > 0) {
            events.push({
                type: 'inspection',
                time: '10:00 AM',
                title: 'HQS Inspection'
            });
        }
        
        if (random > 1) {
            events.push({
                type: 'work-order',
                time: '2:00 PM',
                title: 'Repair Work'
            });
        }

        return events;
    }

    generateUpcomingEvents() {
        const events = [
            { date: 'Tomorrow', time: '10:00 AM', title: 'Annual HQS Inspection', address: '347 Oak Street, Unit 2A', type: 'inspection' },
            { date: 'Jul 23', time: '2:00 PM', title: 'Plumbing Repair', address: '128 Pine Avenue', type: 'work-order' },
            { date: 'Jul 24', time: '11:00 AM', title: 'Certification Renewal', address: '456 First Street', type: 'certification' },
            { date: 'Jul 25', time: '9:00 AM', title: 'Re-inspection', address: '789 Elm Drive', type: 'inspection' }
        ];

        return events.map(event => `
            <div class="upcoming-event">
                <div class="event-date">${event.date}</div>
                <div class="event-details">
                    <div class="event-title">${event.title}</div>
                    <div class="event-address">${event.address}</div>
                    <div class="event-time">${event.time}</div>
                </div>
                <div class="event-type ${event.type}"></div>
            </div>
        `).join('');
    }

    generateEmailAnalysis() {
        const emails = [
            {
                subject: 'HQS Inspection Results - 347 Oak Street',
                time: '15 minutes ago',
                confidence: 95,
                extracted: {
                    property: '347 Oak Street, Unit 2A',
                    inspector: 'Sarah Wilson',
                    status: 'Failed',
                    deadline: '30 days',
                    issues: ['Electrical violations', 'Plumbing issues']
                },
                actions: ['Schedule repairs', 'Contact contractor', 'Set reminder']
            },
            {
                subject: 'Work Order Completion - Pine Avenue',
                time: '1 hour ago',
                confidence: 88,
                extracted: {
                    property: '128 Pine Avenue, Unit 1B',
                    contractor: 'ABC Repairs',
                    status: 'Completed',
                    cost: '$1,250',
                    nextAction: 'Schedule follow-up inspection'
                },
                actions: ['Mark completed', 'Process payment', 'Schedule inspection']
            }
        ];

        return emails.map(email => `
            <div class="email-analysis-item">
                <div class="email-header">
                    <strong>${email.subject}</strong>
                    <span class="email-time">${email.time}</span>
                    <span class="confidence-badge">${email.confidence}% confident</span>
                </div>
                <div class="extracted-data">
                    <h4>Extracted Information:</h4>
                    <ul>
                        ${Object.entries(email.extracted).map(([key, value]) => 
                            `<li><strong>${key}:</strong> ${Array.isArray(value) ? value.join(', ') : value}</li>`
                        ).join('')}
                    </ul>
                </div>
                <div class="suggested-actions">
                    <h4>Suggested Actions:</h4>
                    <div class="action-buttons">
                        ${email.actions.map(action => 
                            `<button class="btn-sm">${action}</button>`
                        ).join('')}
                    </div>
                </div>
            </div>
        `).join('');
    }

    generateAIInsights() {
        const insights = [
            {
                type: 'trend',
                title: 'Inspection Pattern Detected',
                description: 'Properties on Oak Street have 40% more electrical issues than average',
                action: 'Recommend electrical system evaluation'
            },
            {
                type: 'prediction',
                title: 'Upcoming Deadline Risk',
                description: '3 properties likely to miss certification deadlines based on current progress',
                action: 'Send proactive reminders'
            },
            {
                type: 'optimization',
                title: 'Workflow Improvement',
                description: 'Grouping inspections by area could save 20% travel time',
                action: 'Optimize scheduling'
            }
        ];

        return insights.map(insight => `
            <div class="ai-insight">
                <div class="insight-type ${insight.type}">
                    <i class="fas fa-${insight.type === 'trend' ? 'chart-line' : insight.type === 'prediction' ? 'crystal-ball' : 'lightbulb'}"></i>
                </div>
                <div class="insight-content">
                    <h4>${insight.title}</h4>
                    <p>${insight.description}</p>
                    <button class="btn-sm">${insight.action}</button>
                </div>
            </div>
        `).join('');
    }

    setupCalendarEvents() {
        // Add event listeners for calendar
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
                this.filterCalendarEvents(e.target.dataset.filter);
            });
        });
    }

    filterCalendarEvents(filter) {
        const events = document.querySelectorAll('.event');
        events.forEach(event => {
            if (filter === 'all' || event.classList.contains(filter)) {
                event.style.display = 'block';
            } else {
                event.style.display = 'none';
            }
        });
    }

    handleButtonClick(e) {
        const button = e.target;
        const action = button.textContent.trim();

        // Simulate different actions
        switch(action) {
            case 'Take Action':
                this.showActionModal();
                break;
            case 'View Details':
                this.showDetailsModal();
                break;
            case 'Schedule':
            case 'Schedule Certification':
                this.showScheduleModal();
                break;
            default:
                this.simulateAction(action);
        }
    }

    showActionModal() {
        this.showModal('Take Action', `
            <div class="action-modal">
                <h3>Critical Item: Annual HQS Inspection</h3>
                <p><strong>Property:</strong> 347 Oak Street, Unit 2A</p>
                <p><strong>Issue:</strong> Missing Quality Standards inspection</p>
                
                <div class="action-options">
                    <button class="btn btn-danger">Schedule Emergency Inspection</button>
                    <button class="btn">Contact Housing Authority</button>
                    <button class="btn btn-outline">Set Reminder</button>
                </div>
            </div>
        `);
    }

    showDetailsModal() {
        this.showModal('Inspection Details', `
            <div class="details-modal">
                <h3>Property Inspection History</h3>
                <div class="inspection-timeline">
                    <div class="timeline-item">
                        <div class="timeline-date">2024-01-15</div>
                        <div class="timeline-content">
                            <strong>Last Inspection:</strong> Passed with minor issues
                            <br><small>Inspector: John Smith</small>
                        </div>
                    </div>
                    <div class="timeline-item current">
                        <div class="timeline-date">Due Now</div>
                        <div class="timeline-content">
                            <strong>Annual HQS Inspection:</strong> Overdue by 2 days
                            <br><small>Action required immediately</small>
                        </div>
                    </div>
                </div>
            </div>
        `);
    }

    showScheduleModal() {
        this.showModal('Schedule Inspection', `
            <div class="schedule-modal">
                <h3>Schedule New Inspection</h3>
                <form class="schedule-form">
                    <div class="form-group">
                        <label>Property:</label>
                        <select>
                            <option>347 Oak Street, Unit 2A</option>
                            <option>128 Pine Avenue, Unit 1B</option>
                            <option>456 First Street, Unit 2A</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Inspection Type:</label>
                        <select>
                            <option>Annual HQS Inspection</option>
                            <option>Re-inspection</option>
                            <option>Move-in Inspection</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Preferred Date:</label>
                        <input type="date" min="${new Date().toISOString().split('T')[0]}">
                    </div>
                    <div class="form-group">
                        <label>Inspector:</label>
                        <select>
                            <option>Sarah Wilson</option>
                            <option>Mark Johnson</option>
                            <option>Auto-assign</option>
                        </select>
                    </div>
                    <button type="submit" class="btn">Schedule Inspection</button>
                </form>
            </div>
        `);
    }

    showModal(title, content) {
        const modal = document.createElement('div');
        modal.className = 'modal-overlay';
        modal.innerHTML = `
            <div class="modal">
                <div class="modal-header">
                    <h2>${title}</h2>
                    <button class="modal-close">&times;</button>
                </div>
                <div class="modal-content">
                    ${content}
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Close modal events
        modal.querySelector('.modal-close').addEventListener('click', () => {
            modal.remove();
        });

        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                modal.remove();
            }
        });

        // Handle form submission
        const form = modal.querySelector('form');
        if (form) {
            form.addEventListener('submit', (e) => {
                e.preventDefault();
                this.showNotification('Inspection scheduled successfully!', 'success');
                modal.remove();
            });
        }
    }

    simulateAction(action) {
        this.showNotification(`${action} - Feature coming soon!`, 'info');
    }

    showNotification(message, type = 'info') {
        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.innerHTML = `
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            <span>${message}</span>
        `;

        document.body.appendChild(notification);

        setTimeout(() => {
            notification.classList.add('show');
        }, 100);

        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => notification.remove(), 300);
        }, 3000);
    }

    updateDashboardData() {
        // Simulate real-time data updates
        const stats = document.querySelectorAll('.stat-number');
        stats.forEach(stat => {
            const currentValue = parseInt(stat.textContent);
            const change = Math.floor(Math.random() * 3) - 1; // -1, 0, or 1
            const newValue = Math.max(0, currentValue + change);
            
            if (change !== 0) {
                stat.textContent = newValue;
                stat.parentElement.style.transform = 'scale(1.05)';
                setTimeout(() => {
                    stat.parentElement.style.transform = 'scale(1)';
                }, 200);
            }
        });
    }

    startRealTimeUpdates() {
        // Simulate real-time updates every 30 seconds
        setInterval(() => {
            if (this.currentTab === 'dashboard') {
                this.updateDashboardData();
            }
        }, 30000);

        // Simulate new email alerts
        setInterval(() => {
            if (Math.random() > 0.7) { // 30% chance
                this.simulateNewEmail();
            }
        }, 45000);
    }

    simulateNewEmail() {
        const emails = [
            'New inspection scheduled for 789 Maple Drive',
            'Work order completed at 456 Pine Street',
            'Urgent: Failed re-inspection at 123 Oak Avenue',
            'Certification renewal reminder for 890 Elm Street'
        ];

        const randomEmail = emails[Math.floor(Math.random() * emails.length)];
        this.showNotification(`New Email: ${randomEmail}`, 'info');
    }

    animateStatsCards() {
        const cards = document.querySelectorAll('.stat-card');
        cards.forEach((card, index) => {
            setTimeout(() => {
                card.style.transform = 'translateY(0)';
                card.style.opacity = '1';
            }, index * 150);
        });
    }

    setupDemoFeatures() {
        // Add demo indicators and tooltips
        const demoElements = document.querySelectorAll('.btn, .stat-card, .deadline-item');
        demoElements.forEach(element => {
            element.addEventListener('mouseenter', () => {
                if (!element.querySelector('.demo-tooltip')) {
                    const tooltip = document.createElement('div');
                    tooltip.className = 'demo-tooltip';
                    tooltip.textContent = 'Click to see demo functionality';
                    element.appendChild(tooltip);
                }
            });

            element.addEventListener('mouseleave', () => {
                const tooltip = element.querySelector('.demo-tooltip');
                if (tooltip) {
                    tooltip.remove();
                }
            });
        });
    }

    generateMockData() {
        return {
            properties: [
                { address: '347 Oak Street, Unit 2A', status: 'critical', lastInspection: '2024-01-15' },
                { address: '128 Pine Avenue, Unit 1B', status: 'compliant', lastInspection: '2024-06-20' },
                { address: '456 First Street, Unit 2A', status: 'pending', lastInspection: '2024-05-10' },
                { address: '789 Elm Drive, Unit 3C', status: 'compliant', lastInspection: '2024-07-01' }
            ],
            stats: {
                totalProperties: 24,
                activeInspections: 8,
                pendingWorkOrders: 15,
                upcomingCertifications: 6,
                complianceRate: 92
            }
        };
    }
}

// Additional CSS for dynamic elements (injected via JavaScript)
const dynamicStyles = `
    <style>
    .modal-overlay {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        display: flex;
        align-items: center;
        justify-content: center;
        z-index: 1000;
    }

    .modal {
        background: white;
        border-radius: 12px;
        max-width: 500px;
        width: 90%;
        max-height: 80vh;
        overflow-y: auto;
    }

    .modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1.5rem;
        border-bottom: 1px solid #e5e7eb;
    }

    .modal-close {
        background: none;
        border: none;
        font-size: 1.5rem;
        cursor: pointer;
        color: #6b7280;
    }

    .modal-content {
        padding: 1.5rem;
    }

    .notification {
        position: fixed;
        top: 20px;
        right: 20px;
        background: white;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        padding: 1rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        display: flex;
        align-items: center;
        gap: 0.5rem;
        transform: translateX(100%);
        transition: transform 0.3s ease;
        z-index: 1001;
        min-width: 300px;
    }

    .notification.show {
        transform: translateX(0);
    }

    .notification.success {
        border-color: #10b981;
        color: #10b981;
    }

    .notification.error {
        border-color: #dc2626;
        color: #dc2626;
    }

    .notification.info {
        border-color: #3b82f6;
        color: #3b82f6;
    }

    .demo-tooltip {
        position: absolute;
        bottom: 100%;
        left: 50%;
        transform: translateX(-50%);
        background: #1f2937;
        color: white;
        padding: 0.5rem;
        border-radius: 4px;
        font-size: 0.75rem;
        white-space: nowrap;
        z-index: 100;
    }

    .property-calendar-view,
    .email-analysis-view,
    .settings-view {
        animation: fadeIn 0.3s ease;
    }

    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
    }

    .calendar-grid {
        display: grid;
        gap: 1px;
        background: #e5e7eb;
        border-radius: 8px;
        overflow: hidden;
        margin: 2rem 0;
    }

    .calendar-week {
        display: grid;
        grid-template-columns: repeat(7, 1fr);
        gap: 1px;
    }

    .calendar-day {
        background: white;
        padding: 1rem;
        min-height: 120px;
        cursor: pointer;
    }

    .calendar-day.today {
        background: #eff6ff;
    }

    .day-header {
        display: flex;
        justify-content: space-between;
        margin-bottom: 0.5rem;
        font-size: 0.85rem;
    }

    .day-number {
        font-weight: 600;
    }

    .event {
        background: #3b82f6;
        color: white;
        padding: 0.25rem;
        border-radius: 4px;
        font-size: 0.7rem;
        margin-bottom: 0.25rem;
    }

    .event.inspection { background: #dc2626; }
    .event.work-order { background: #d97706; }
    .event.certification { background: #059669; }

    .form-group {
        margin-bottom: 1rem;
    }

    .form-group label {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 500;
    }

    .form-group input,
    .form-group select {
        width: 100%;
        padding: 0.5rem;
        border: 1px solid #d1d5db;
        border-radius: 6px;
    }

    .status-indicator {
        padding: 0.25rem 0.75rem;
        border-radius: 20px;
        font-size: 0.8rem;
        font-weight: 500;
    }

    .status-indicator.connected {
        background: #d1fae5;
        color: #059669;
    }

    .settings-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        gap: 2rem;
        margin-top: 2rem;
    }

    .settings-card {
        background: white;
        border-radius: 12px;
        padding: 1.5rem;
        border: 1px solid #e5e7eb;
    }

    .setting-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid #f3f4f6;
    }

    .analysis-stats {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
        gap: 1rem;
        margin: 2rem 0;
    }

    .stat-box {
        background: white;
        padding: 1.5rem;
        border-radius: 8px;
        text-align: center;
        border: 1px solid #e5e7eb;
    }

    .stat-box .stat-number {
        font-size: 2rem;
        font-weight: 700;
        color: #1f2937;
    }

    .stat-box .stat-label {
        color: #6b7280;
        font-size: 0.9rem;
    }
    </style>
`;

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Inject dynamic styles
    document.head.insertAdjacentHTML('beforeend', dynamicStyles);
    
    // Initialize the CalendarAI application
    window.calendarAI = new CalendarAI();
});
