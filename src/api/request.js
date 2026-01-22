/**
 * 网络请求封装工具
 * 基于 Axios，适配 RuoYi-FastAPI 接口规范
 */

import axios from 'axios'
import { showToast } from 'vant'
import router from '@/router'

// 创建axios实例
// 开发环境使用代理，生产环境直接请求
const isDev = import.meta.env.DEV
const request = axios.create({
  baseURL: isDev ? '/api' : 'http://101.42.15.26:9100',
  timeout: 10000
})

// 请求拦截器
request.interceptors.request.use(
  config => {
    // 添加认证token
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }

    // 登录接口使用 form-data
    if (config.url === '/login') {
      config.headers['Content-Type'] = 'application/x-www-form-urlencoded'
    }

    return config
  },
  error => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
request.interceptors.response.use(
  response => {
    const res = response.data

    // 成功返回
    if (res.code === 200) {
      return res
    }

    // 业务错误处理
    const errorMsg = res.msg || '操作失败'
    showToast({
      message: errorMsg,
      duration: 2000
    })

    return Promise.reject(res)
  },
  error => {
    console.error('响应错误:', error)

    // Token过期，跳转登录页
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      showToast({
        message: '登录已过期',
        duration: 1500
      })
      setTimeout(() => {
        router.replace('/login')
      }, 1500)
      return Promise.reject({ code: 401, msg: '登录已过期' })
    }

    // 网络错误
    showToast({
      message: '网络请求失败',
      duration: 2000
    })

    return Promise.reject(error)
  }
)

export default request
