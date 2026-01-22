/**
 * API接口定义
 * 基于小程序 utils/request.js 改造
 */

import request from './request'

// ============ 认证相关接口 ============

/**
 * 获取验证码
 */
export function getCaptcha() {
  return request.get('/captchaImage', {}, { needAuth: false })
}

/**
 * 用户登录
 * @param {string} username - 用户名
 * @param {string} password - 密码
 * @param {string} code - 验证码
 * @param {string} uuid - 验证码UUID
 */
export function login(username, password, code = '', uuid = '') {
  return request.post('/login', { username, password, code, uuid })
}

/**
 * 获取用户信息
 */
export function getUserInfo() {
  return request.get('/getInfo')
}

/**
 * 退出登录
 */
export function logout() {
  return request.post('/logout')
}

// ============ 工作日志接口 ============

/**
 * 获取月历数据
 * @param {number} year - 年份
 * @param {number} month - 月份
 */
export function getMonthLogs(year, month) {
  return request.get(`/work-logs/calendar/${year}/${month}`)
}

/**
 * 获取周历数据
 * @param {string} start - 周开始日期 (YYYY-MM-DD)
 */
export function getWeekLogs(start) {
  return request.get('/work-logs/week', { params: { start } })
}

/**
 * 获取日志详情
 * @param {number} logId - 日志ID
 */
export function getLogDetail(logId) {
  return request.get(`/work-logs/${logId}`)
}

/**
 * 新增日志
 * @param {object} data - 日志数据 {log_date, content, summary, remark}
 */
export function addLog(data) {
  return request.post('/work-logs', data)
}

/**
 * 编辑日志
 * @param {object} data - 日志数据 {id, log_date, content, summary, remark}
 */
export function updateLog(data) {
  return request.put('/work-logs', data)
}

/**
 * 删除日志
 * @param {number} logId - 日志ID
 */
export function deleteLog(logId) {
  return request.delete(`/work-logs/${logId}`)
}

/**
 * 获取指定用户的月历数据（管理员）
 * @param {number} userId - 用户ID
 * @param {number} year - 年份
 * @param {number} month - 月份
 */
export function getUserMonthLogs(userId, year, month) {
  return request.get(`/work-logs/user/${userId}/calendar/${year}/${month}`)
}

/**
 * 获取指定用户的周历数据（管理员）
 * @param {number} userId - 用户ID
 * @param {string} start - 周开始日期
 */
export function getUserWeekLogs(userId, start) {
  return request.get(`/work-logs/user/${userId}/week`, { params: { start } })
}

// ============ 用户模块接口 ============

/**
 * 获取用户列表
 * @param {object} params - 查询参数 {pageNum, pageSize, userName, phonenumber, status}
 */
export function getUserList(params) {
  return request.get('/system/user/list', { params })
}

/**
 * 获取用户详情
 * @param {number} userId - 用户ID
 */
export function getUserDetail(userId) {
  return request.get(`/system/user/${userId}`)
}

// ============ 通用模块接口 ============

/**
 * 文件上传
 * @param {File} file - 文件对象
 */
export function uploadFile(file) {
  const formData = new FormData()
  formData.append('file', file)

  return request.post('/common/upload', formData, {
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}
