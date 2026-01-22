<template>
  <div class="log-detail-page">
    <!-- 导航栏 -->
    <van-nav-bar
      :title="readonly ? `${logStore.viewingUserName}的日志` : (logId ? '编辑日志' : '添加日志')"
      left-arrow
      @click-left="onClickLeft"
    />

    <!-- 日期选择卡片 -->
    <div class="date-card">
      <van-field
        v-model="displayDate"
        :readonly="!!logId"
        :clickable="!logId"
        @click="!logId && (showDatePicker = true)"
      >
        <template #left-icon>
          <span class="date-icon">📅</span>
        </template>
        <template #button>
          <van-icon name="arrow" v-if="!logId" />
        </template>
      </van-field>
    </div>

    <!-- 内容输入卡片 -->
    <div class="content-card">
      <van-field
        v-model="content"
        type="textarea"
        rows="15"
        autosize
        placeholder="记录今天的工作内容..."
        maxlength="5000"
        show-word-limit
        :readonly="readonly"
      />
    </div>

    <!-- 只读模式提示 -->
    <div class="readonly-tip" v-if="readonly">
      <van-notice-bar
        left-icon="info-o"
        text="这是只读模式，无法编辑他人日志"
      />
    </div>

    <!-- 底部安全区 -->
    <div class="safe-area"></div>

    <!-- 底部操作栏 -->
    <div class="bottom-bar" v-if="!readonly">
      <button class="delete-btn" @click="handleDelete" v-if="logId">
        删除
      </button>
      <button class="save-btn" @click="handleSave" :disabled="saving">
        {{ saving ? '保存中...' : '保存' }}
      </button>
    </div>

    <!-- 日期选择弹窗 -->
    <van-popup v-model:show="showDatePicker" position="bottom" v-if="!readonly">
      <van-date-picker
        v-model="pickerDate"
        :min-date="minDate"
        :max-date="maxDate"
        @confirm="onDateConfirm"
        @cancel="showDatePicker = false"
      />
    </van-popup>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { showToast, showDialog } from 'vant'
import { DatePicker } from 'vant'
import { getLogDetail, addLog, updateLog, deleteLog as deleteLogApi } from '@/api'
import { useLogStore } from '@/stores/log'

const router = useRouter()
const route = useRoute()
const logStore = useLogStore()

// 返回上一页
function onClickLeft() {
  router.back()
}

// 数据
const logId = ref(null)
const logDate = ref('')
const displayDate = ref('')
const content = ref('')
const saving = ref(false)
const showDatePicker = ref(false)
const pickerDate = ref(new Date())

// 是否只读模式（查看他人日志时只读）
const readonly = computed(() => !!logStore.viewingUserId)

// 日期范围限制
const minDate = ref(new Date(2020, 0, 1))
const maxDate = ref(new Date(2030, 11, 31))

onMounted(() => {
  console.log('LogDetail onMounted')
  console.log('route.params:', route.params)
  console.log('route.query:', route.query)

  // id 是路由参数，date 是查询参数
  const id = route.params.id
  const { date } = route.query

  console.log('解析的参数 - id:', id, 'date:', date)

  if (id) {
    // 编辑模式
    console.log('编辑模式，id:', id)
    logId.value = Number(id)
    loadLogDetail()
    // 编辑模式下，先设置 URL 中的 date（后端 API 的 log_date 字段可能为 null）
    if (date) {
      console.log('使用 URL 参数中的日期:', date)
      setDateValue(date)
    }
  } else if (date) {
    // 新增模式，使用指定日期
    console.log('新增模式，date:', date)
    setDateValue(date)
  } else {
    // 默认使用今天
    const today = formatDate(new Date())
    console.log('默认模式，使用今天:', today)
    setDateValue(today)
  }
})

// 设置日期值
function setDateValue(dateStr) {
  console.log('setDateValue 被调用，传入参数:', dateStr)
  console.log('dateStr 类型:', typeof dateStr)
  console.log('dateStr 是否为 null:', dateStr === null)
  console.log('dateStr 是否为 undefined:', dateStr === undefined)

  logDate.value = dateStr
  console.log('设置后的 logDate.value:', logDate.value)

  const date = new Date(dateStr)
  console.log('解析后的 Date 对象:', date)
  console.log('Date 是否有效:', !isNaN(date.getTime()))

  const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  displayDate.value = `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日 ${weekdays[date.getDay()]}`

  console.log('设置后的 displayDate.value:', displayDate.value)
}

// 加载日志详情
function loadLogDetail() {
  console.log('开始加载日志详情，logId:', logId.value)
  getLogDetail(logId.value).then(res => {
    console.log('日志详情API返回完整对象:', res)
    console.log('res.data:', res.data)
    const log = res.data
    console.log('解析的日志数据:', log)
    console.log('log.log_date:', log.log_date)
    console.log('log的所有字段:', JSON.stringify(log, null, 2))

    // 只设置内容，不设置日期（因为 API 返回的 log_date 可能为 null）
    // 如果 API 返回了有效的 log_date，则使用它；否则保持已有的日期
    if (log.log_date) {
      console.log('API 返回了有效的 log_date，使用它:', log.log_date)
      setDateValue(log.log_date)
    } else {
      console.log('API 返回的 log_date 为空，保持已有日期:', logDate.value)
    }

    content.value = log.content || ''
    console.log('设置content后的值:', content.value)
    console.log('设置后的logDate.value:', logDate.value)
  }).catch(err => {
    console.error('加载日志详情失败:', err)
    showToast('加载失败')
  })
}

// 格式化日期
function formatDate(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

// 日期确认
function onDateConfirm() {
  const dateStr = formatDate(pickerDate.value)
  setDateValue(dateStr)
  showDatePicker.value = false
}

// 保存日志
function handleSave() {
  console.log('=== 开始保存日志 ===')
  console.log('当前状态 - logId:', logId.value)
  console.log('当前状态 - logDate:', logDate.value)
  console.log('当前状态 - content长度:', content.value?.length)
  console.log('当前状态 - readonly:', readonly.value)
  console.log('当前状态 - viewingUserId:', logStore.viewingUserId)

  if (saving.value) {
    console.log('正在保存中，跳过')
    return
  }

  // 验证
  if (!content.value.trim()) {
    console.log('验证失败：内容为空')
    showToast('请输入工作内容')
    return
  }

  // 确保日期存在
  let finalLogDate = logDate.value
  if (!finalLogDate) {
    finalLogDate = formatDate(new Date())
    logDate.value = finalLogDate
  }

  // 自动生成摘要（取内容前50个字）
  const summary = content.value.replace(/<[^>]+>/g, '').substring(0, 50)

  const logData = {
    log_date: finalLogDate,
    content: content.value,
    summary: summary
  }

  console.log('准备保存的数据:', logData)
  console.log('是否为编辑模式:', !!logId.value)

  if (logId.value) {
    console.log('编辑模式，完整数据:', { ...logData, id: logId.value })
  }

  saving.value = true

  const request = logId.value
    ? updateLog({ ...logData, id: logId.value })
    : addLog(logData)

  request.then((res) => {
    console.log('保存成功，响应:', res)
    showToast(logId.value ? '修改成功' : '添加成功')
    setTimeout(() => {
      router.back()
    }, 1000)
  }).catch(err => {
    console.error('保存失败，错误详情:', err)
    console.error('错误信息:', JSON.stringify(err, null, 2))
    showToast(err.msg || '保存失败，请重试')
  }).finally(() => {
    saving.value = false
    console.log('保存流程结束')
  })
}

// 删除日志
function handleDelete() {
  showDialog({
    title: '确认删除',
    message: '确定要删除这条工作日志吗？删除后无法恢复。',
    confirmButtonText: '删除',
    confirmButtonColor: '#F54A45',
    showCancelButton: true
  }).then(() => {
    deleteLogApi(logId.value).then(() => {
      showToast('删除成功')
      setTimeout(() => {
        router.back()
      }, 1000)
    }).catch(err => {
      showToast(err.msg || '删除失败，请重试')
    })
  }).catch(() => {
    // 用户取消
  })
}
</script>

<style lang="scss" scoped>
.log-detail-page {
  min-height: 100vh;
  background: #F5F6F7;
  padding-bottom: 80px;
}

/* 日期卡片 */
.date-card {
  background: #FFFFFF;
  margin: 16px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

.date-icon {
  font-size: 18px;
  margin-right: 8px;
}

/* 内容卡片 */
.content-card {
  background: #FFFFFF;
  margin: 16px;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
}

/* 只读提示 */
.readonly-tip {
  padding: 0 16px;
}

/* 底部安全区 */
.safe-area {
  height: 34px;
}

/* 底部操作栏 */
.bottom-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  display: flex;
  gap: 12px;
  padding: 12px 16px;
  padding-bottom: calc(12px + env(safe-area-inset-bottom));
  background: #FFFFFF;
  border-top: 1px solid #E4E7ED;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.04);
}

.delete-btn {
  flex: 1;
  height: 48px;
  background: #FFFFFF;
  border: 1px solid #F54A45;
  border-radius: 8px;
  color: #F54A45;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;

  &:active {
    background: #FFF0F0;
  }
}

.save-btn {
  flex: 2;
  height: 48px;
  background: #3370FF;
  border: none;
  border-radius: 8px;
  color: #FFFFFF;
  font-size: 16px;
  font-weight: 500;
  cursor: pointer;

  &:active:not(:disabled) {
    background: #2E5ACC;
  }

  &:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
}

/* Vant组件样式覆盖 */
:deep(.van-field__control) {
  font-size: 15px;
  color: #1F2329;
}

:deep(.van-field__body) {
  padding: 16px;
}

:deep(.van-cell) {
  padding: 12px 16px;
}

:deep(.van-cell__value) {
  font-size: 15px;
  color: #1F2329;
}

:deep(.van-textarea__word-limit) {
  color: #8F959E;
}
</style>
