<template>
  <div class="home-page">
    <!-- 导航栏占位 -->
    <div class="navbar-placeholder"></div>

    <!-- 周选择器 -->
    <div class="week-selector">
      <div class="week-nav">
        <div class="nav-arrow" @click="changeWeek(-1)">◀</div>
        <div class="week-info">
          <div class="week-range" @click="showDatePicker = true">
            {{ weekRangeText }}
          </div>
          <!-- 查看他人日志提示 -->
          <div class="viewing-hint" v-if="logStore.viewingUserId">
            <span class="hint-icon">👁</span>
            <span class="hint-text">正在查看：{{ logStore.viewingUserName }}的日志</span>
          </div>
        </div>
        <div class="nav-actions">
          <!-- 返回我的日志按钮（查看他人时显示） -->
          <div class="action-btn back-btn" v-if="logStore.viewingUserId" @click="backToMyLogs">
            返回我的
          </div>
          <!-- 切换用户按钮（有权限且查看自己时显示） -->
          <div class="action-btn switch-btn" v-if="canViewOthers && !logStore.viewingUserId" @click="goToUserList">
            切换用户
          </div>
          <div class="nav-arrow" @click="changeWeek(1)">▶</div>
        </div>
      </div>
      <div class="view-toggles">
        <div class="toggle-btn active">列表</div>
        <div class="toggle-btn" @click="goToCalendar">日历</div>
      </div>
    </div>

    <!-- 内容区 -->
    <div class="content-scroll">
      <!-- 加载状态 -->
      <div class="loading-container" v-if="logStore.loading">
        <div class="loading-spinner"></div>
        <div class="loading-text">加载中...</div>
      </div>

      <!-- 日志卡片列表 -->
      <div class="log-card" v-for="log in displayLogs" :key="log.log_date" v-else>
        <div class="card-header">
          <div class="card-date-box">
            <div class="date-badge">
              <div class="date-day">{{ log.day }}</div>
              <div class="date-month">{{ log.weekday }}</div>
            </div>
            <div class="date-info">
              <div class="date-text">{{ log.dateText }}</div>
            </div>
          </div>
          <div class="card-actions">
            <div class="action-btn edit" @click="editLog(log)">
              <span class="action-icon">✏️</span>
            </div>
            <div class="action-btn delete" @click="deleteLog(log)">
              <span class="action-icon">🗑️</span>
            </div>
          </div>
        </div>
        <div class="card-body" @click="goToDetail(log)">
          <div class="work-section">
            <div class="work-label">今日工作</div>
            <div class="work-content" :class="{ 'work-placeholder': !log.hasLog }">
              <span>{{ log.hasLog ? log.summary : '暂无工作内容' }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部安全区 -->
    <div class="safe-area"></div>

    <!-- 底部悬浮添加按钮 -->
    <div class="floating-add-btn" @click="addLog" v-if="!logStore.viewingUserId">+</div>

    <!-- 日期选择弹窗 -->
    <van-popup v-model:show="showDatePicker" position="bottom">
      <van-date-picker
        v-model="pickerDate"
        title="选择日期"
        :min-date="minDate"
        :max-date="maxDate"
        @confirm="onDateConfirm"
        @cancel="showDatePicker = false"
      />
    </van-popup>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onActivated } from 'vue'
import { useRouter } from 'vue-router'
import { showDialog, showToast } from 'vant'
import { useLogStore } from '@/stores/log'
import { useUserStore } from '@/stores/user'
import { deleteLog as deleteLogApi } from '@/api'

const router = useRouter()
const logStore = useLogStore()
const userStore = useUserStore()

// 显示的日志列表
const displayLogs = ref([])
const weekRangeText = ref('')

// 日期选择器
const showDatePicker = ref(false)
const pickerDate = ref([new Date().getFullYear(), new Date().getMonth() + 1, new Date().getDate()])
const minDate = ref(new Date(2020, 0, 1))
const maxDate = ref(new Date(2030, 11, 31))

// 权限
const canViewOthers = computed(() => userStore.canViewOthers)

// 初始化
onMounted(() => {
  initWeekData()
  loadWeekLogs()
})

onActivated(() => {
  loadWeekLogs()
})

// 初始化周数据
function initWeekData() {
  const today = new Date()
  const weekStart = getWeekMonday(today)
  const weekEnd = getWeekSunday(today)

  logStore.weekStart = weekStart
  logStore.weekEnd = weekEnd
  weekRangeText.value = formatWeekRange(weekStart, weekEnd)
}

// 获取本周一的日期
function getWeekMonday(date) {
  const day = date.getDay() || 7
  const monday = new Date(date)
  monday.setDate(date.getDate() - day + 1)
  return formatDate(monday)
}

// 获取本周日的日期
function getWeekSunday(date) {
  const day = date.getDay() || 7
  const sunday = new Date(date)
  sunday.setDate(date.getDate() - day + 7)
  return formatDate(sunday)
}

// 格式化日期 YYYY-MM-DD
function formatDate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// 格式化周范围显示
function formatWeekRange(start, end) {
  const startDate = new Date(start)
  const endDate = new Date(end)

  const startMonth = startDate.getMonth() + 1
  const startDay = startDate.getDate()
  const endMonth = endDate.getMonth() + 1
  const endDay = endDate.getDate()

  if (startMonth === endMonth) {
    return `${startMonth}月${startDay}日 - ${endDay}日`
  } else {
    return `${startMonth}月${startDay}日 - ${endMonth}月${endDay}日`
  }
}

// 切换周
function changeWeek(offset) {
  const weekStart = new Date(logStore.weekStart)
  weekStart.setDate(weekStart.getDate() + offset * 7)

  const weekEnd = new Date(weekStart)
  weekEnd.setDate(weekEnd.getDate() + 6)

  const newWeekStart = formatDate(weekStart)
  const newWeekEnd = formatDate(weekEnd)

  logStore.weekStart = newWeekStart
  logStore.weekEnd = newWeekEnd
  logStore.weekOffset += offset
  weekRangeText.value = formatWeekRange(newWeekStart, newWeekEnd)

  loadWeekLogs()
}

// 加载周日志
async function loadWeekLogs() {
  try {
    const res = await logStore.fetchWeekLogs(logStore.weekStart)
    console.log('周日志API返回:', res)
    console.log('解析的logs数组:', res.data?.logs)
    displayLogs.value = generateWeekDays(res.data?.logs || [])
  } catch (error) {
    console.error('加载日志失败:', error)
  }
}

// 生成完整的7天数据
function generateWeekDays(apiLogs) {
  const weekdayMap = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  const fullWeekdayMap = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日']

  console.log('apiLogs原始数据:', apiLogs)

  const logMap = {}
  apiLogs.forEach(log => {
    console.log('处理日志对象:', log)
    if (log.id) {
      logMap[log.log_date] = log
    }
  })

  console.log('生成的logMap:', logMap)

  const weekDays = []
  for (let i = 0; i < 7; i++) {
    const date = new Date(logStore.weekStart)
    date.setDate(date.getDate() + i)

    const dateStr = formatDate(date)
    const day = date.getDate()
    const month = date.getMonth() + 1
    const weekday = date.getDay() - 1

    if (logMap[dateStr]) {
      weekDays.push({
        ...logMap[dateStr],
        day,
        weekday: weekdayMap[weekday],
        fullWeekday: fullWeekdayMap[weekday],
        dateText: `${month}月${day}日`,
        hasLog: true
      })
    } else {
      weekDays.push({
        id: null,
        log_date: dateStr,
        summary: '',
        content: '',
        day,
        weekday: weekdayMap[weekday],
        fullWeekday: fullWeekdayMap[weekday],
        dateText: `${month}月${day}日`,
        hasLog: false
      })
    }
  }

  return weekDays
}

// 跳转到日历页面
function goToCalendar() {
  router.replace('/calendar')
}

// 跳转到日志详情（统一使用 date 参数）
function goToDetail(log) {
  console.log('点击日志卡片，完整的log对象:', log)
  console.log('log.log_date:', log.log_date)
  // 统一跳转到编辑页面，根据 date 自动判断是新增还是编辑
  router.push(`/log?date=${log.log_date}`)
}

// 编辑日志（统一使用 date 参数）
function editLog(log) {
  if (!log) {
    showToast('该日期暂无日志，请点击卡片添加')
    return
  }
  // 统一跳转到编辑页面，根据 date 自动判断是新增还是编辑
  router.push(`/log?date=${log.log_date}`)
}

// 删除日志
function deleteLog(log) {
  if (!log || !log.hasLog || !log.id) {
    showToast('该日期暂无日志')
    return
  }

  showDialog({
    title: '确认删除',
    message: '确定要删除这条工作日志吗？删除后无法恢复。',
    confirmButtonText: '删除',
    confirmButtonColor: '#F54A45',
    showCancelButton: true
  }).then(async () => {
    try {
      await deleteLogApi(log.id)
      showToast('删除成功')
      loadWeekLogs()
    } catch (error) {
      showToast(error.msg || '删除失败，请重试')
    }
  }).catch(() => {
    // 用户取消
  })
}

// 添加日志
function addLog() {
  if (logStore.viewingUserId) {
    showToast('无法为他人添加日志')
    return
  }

  const today = formatDate(new Date())
  router.push(`/log?date=${today}`)
}

// 日期选择确认
function onDateConfirm() {
  const [year, month, day] = pickerDate.value
  const selectedDate = new Date(year, month - 1, day)

  // 计算选中日期的周一
  const weekMonday = getWeekMonday(selectedDate)
  const weekSunday = getWeekSunday(selectedDate)

  logStore.weekStart = weekMonday
  logStore.weekEnd = weekSunday
  weekRangeText.value = formatWeekRange(weekMonday, weekSunday)

  showDatePicker.value = false
  loadWeekLogs()
}

// 返回我的日志
function backToMyLogs() {
  logStore.clearViewingUser()
  initWeekData()
  loadWeekLogs()
}

// 跳转到用户列表
function goToUserList() {
  router.push('/users')
}
</script>

<style lang="scss" scoped>
.home-page {
  min-height: 100vh;
  background: #F5F6F7;
  padding-bottom: 50px;
}

/* 导航栏占位 */
.navbar-placeholder {
  height: 56px;
  background: #FFFFFF;
}

/* 周选择器 */
.week-selector {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  background: #FFFFFF;
  padding: 68px 16px 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid #E4E7ED;
  z-index: 998;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
}

.week-nav {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
}

.nav-arrow {
  width: 32px;
  height: 32px;
  border: 1px solid #DEE0E3;
  border-radius: 6px;
  background: #FFFFFF;
  color: #646A73;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  flex-shrink: 0;
  cursor: pointer;

  &:active {
    background: #EBECF0;
    border-color: #3370FF;
  }
}

.week-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.week-range {
  font-size: 15px;
  font-weight: 600;
  color: #1F2329;
  padding: 0 12px;
  cursor: pointer;
  user-select: none;

  &:active {
    opacity: 0.7;
  }
}

/* 查看他人日志提示 */
.viewing-hint {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  background: #FFF7E6;
  border-radius: 4px;
}

.hint-icon {
  font-size: 10px;
}

.hint-text {
  font-size: 11px;
  color: #FF8800;
  font-weight: 500;
}

.nav-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

.action-btn {
  &.back-btn {
    padding: 0 8px;
    height: 28px;
    border: 1px solid #3370FF;
    border-radius: 6px;
    background: #FFFFFF;
    color: #3370FF;
    font-size: 12px;
    font-weight: 500;
    display: flex;
    align-items: center;
    justify-content: center;
    white-space: nowrap;
    cursor: pointer;

    &:active {
      background: #E8F3FF;
    }
  }

  &.switch-btn {
    padding: 0 8px;
    height: 28px;
    border: 1px solid #DEE0E3;
    border-radius: 6px;
    background: #FFFFFF;
    color: #646A73;
    font-size: 12px;
    font-weight: 500;
    display: flex;
    align-items: center;
    justify-content: center;
    white-space: nowrap;
    cursor: pointer;

    &:active {
      background: #F5F6F7;
    }
  }
}

.view-toggles {
  display: flex;
  background: #F5F6F7;
  padding: 3px;
  border-radius: 8px;
  gap: 3px;
}

.toggle-btn {
  padding: 6px 12px;
  border-radius: 6px;
  background: transparent;
  color: #646A73;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;

  &.active {
    background: #FFFFFF;
    color: #3370FF;
  }
}

/* 内容区 */
.content-scroll {
  margin-top: 56px;
  padding: 0 16px 20px;
}

/* 日志卡片 */
.log-card {
  background: #FFFFFF;
  border-radius: 12px;
  margin-bottom: 12px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.04);
  overflow: hidden;

  &:active {
    transform: scale(0.98);
  }
}

.card-header {
  padding: 16px;
  border-bottom: 1px solid #E4E7ED;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.card-date-box {
  display: flex;
  align-items: center;
  gap: 10px;
}

.date-badge {
  width: 48px;
  height: 48px;
  background: #E8F3FF;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.date-day {
  font-size: 20px;
  font-weight: 700;
  color: #3370FF;
  line-height: 1;
}

.date-month {
  font-size: 11px;
  color: #646A73;
  margin-top: 2px;
}

.date-info {
  flex: 1;
}

.date-text {
  font-size: 16px;
  font-weight: 600;
  color: #1F2329;
  margin-bottom: 2px;
}

.card-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  width: 32px;
  height: 32px;
  border-radius: 6px;
  border: 1px solid #DEE0E3;
  background: #FFFFFF;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 5px;
  cursor: pointer;

  &:active {
    transform: scale(0.95);
  }

  &.edit {
    border-color: #3370FF;
  }

  &.delete {
    border-color: #F54A45;
  }

  .action-icon {
    font-size: 14px;
  }
}

.card-body {
  padding: 16px;
  cursor: pointer;
}

.work-section {
  margin-bottom: 12px;

  &:last-child {
    margin-bottom: 0;
  }
}

.work-label {
  font-size: 13px;
  font-weight: 600;
  color: #646A73;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  gap: 6px;

  &::before {
    content: '';
    width: 6px;
    height: 6px;
    background: #3370FF;
    border-radius: 50%;
  }
}

.work-content {
  font-size: 14px;
  line-height: 1.8;
  color: #1F2329;
  padding: 12px;
  background: #F5F6F7;
  border-radius: 8px;
  white-space: pre-wrap;

  &.work-placeholder {
    color: #A4ABB3;
    font-style: italic;
  }
}

/* 加载状态 */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 80px 20px;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #E4E7ED;
  border-top-color: #3370FF;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loading-text {
  margin-top: 16px;
  font-size: 14px;
  color: #8F959E;
}

/* 底部安全区 */
.safe-area {
  height: 34px;
}

/* 底部悬浮添加按钮 */
.floating-add-btn {
  position: fixed;
  bottom: calc(50px + env(safe-area-inset-bottom) + 16px);
  right: 16px;
  width: 64px;
  height: 48px;
  background: #3370FF;
  border-radius: 24px;
  color: white;
  font-size: 28px;
  font-weight: 300;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 16px rgba(51, 112, 255, 0.4);
  z-index: 100;
  line-height: 1;
  cursor: pointer;

  &:active {
    transform: scale(0.95);
  }
}
</style>
