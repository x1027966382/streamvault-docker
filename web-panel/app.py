#!/usr/bin/env python3
"""StreamVault Web 管理面板"""

import os
import json
import subprocess
import glob
from datetime import datetime
from pathlib import Path

from flask import Flask, render_template_string, jsonify, request, redirect, url_for

app = Flask(__name__)

# 配置
DOWNLOAD_DIR = os.environ.get('DOWNLOAD_DIR', '/app/downloads')
LOG_DIR = os.environ.get('LOG_DIR', '/app/log')
CONFIG_DIR = os.environ.get('CONFIG_DIR', '/app/config')

# ===== HTML 模板 =====
TEMPLATE = '''
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>StreamVault 管理面板</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #e2e8f0; min-height: 100vh; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        header { background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%); padding: 20px 0; border-bottom: 1px solid #334155; }
        header h1 { text-align: center; font-size: 1.8em; color: #38bdf8; }
        header p { text-align: center; color: #94a3b8; margin-top: 5px; }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 20px; margin: 20px 0; }
        .card { background: #1e293b; border-radius: 12px; padding: 20px; border: 1px solid #334155; }
        .card h3 { color: #38bdf8; margin-bottom: 10px; font-size: 1.1em; }
        .stat { font-size: 2em; font-weight: bold; color: #f1f5f9; }
        .stat-label { color: #94a3b8; font-size: 0.9em; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #334155; }
        th { color: #94a3b8; font-weight: 500; }
        tr:hover { background: #1e293b; }
        .badge { padding: 3px 10px; border-radius: 20px; font-size: 0.8em; }
        .badge-success { background: #065f46; color: #34d399; }
        .badge-info { background: #1e40af; color: #60a5fa; }
        .badge-warn { background: #92400e; color: #fbbf24; }
        .btn { display: inline-block; padding: 8px 16px; border-radius: 8px; text-decoration: none; color: white; cursor: pointer; border: none; font-size: 0.9em; margin: 5px; }
        .btn-primary { background: #2563eb; }
        .btn-success { background: #059669; }
        .btn-warn { background: #d97706; }
        .btn:hover { opacity: 0.9; }
        .tabs { display: flex; gap: 5px; margin-bottom: 20px; flex-wrap: wrap; }
        .tab { padding: 8px 20px; background: #1e293b; border: 1px solid #334155; border-radius: 8px; color: #94a3b8; cursor: pointer; }
        .tab.active { background: #2563eb; color: white; border-color: #2563eb; }
        .section { display: none; }
        .section.active { display: block; }
        .form-group { margin-bottom: 15px; }
        .form-group label { display: block; color: #94a3b8; margin-bottom: 5px; }
        .form-group input, .form-group textarea { width: 100%; padding: 10px; border: 1px solid #334155; border-radius: 8px; background: #0f172a; color: #e2e8f0; }
        .tree { font-family: monospace; background: #0f172a; padding: 15px; border-radius: 8px; overflow-x: auto; }
        .tree-item { padding: 2px 0; }
        .tree-folder { color: #fbbf24; }
        .tree-file { color: #94a3b8; }
        .refresh-btn { position: fixed; bottom: 20px; right: 20px; width: 50px; height: 50px; border-radius: 50%; background: #2563eb; color: white; border: none; font-size: 1.5em; cursor: pointer; box-shadow: 0 4px 12px rgba(0,0,0,0.3); }
    </style>
</head>
<body>
    <header>
        <h1>🎬 StreamVault</h1>
        <p>视频下载管理面板 v2.0</p>
    </header>
    
    <div class="container">
        <div class="tabs">
            <div class="tab active" onclick="showSection('overview')">📊 总览</div>
            <div class="tab" onclick="showSection('files')">📁 文件管理</div>
            <div class="tab" onclick="showSection('tasks')">📋 任务队列</div>
            <div class="tab" onclick="showSection('config')">⚙️ 配置</div>
            <div class="tab" onclick="showSection('logs')">📝 日志</div>
        </div>
        
        <!-- 总览 -->
        <div id="overview" class="section active">
            <div class="cards">
                <div class="card">
                    <h3>📦 下载文件</h3>
                    <div class="stat" id="total-files">-</div>
                    <div class="stat-label">个文件</div>
                </div>
                <div class="card">
                    <h3>💾 总大小</h3>
                    <div class="stat" id="total-size">-</div>
                    <div class="stat-label">占用空间</div>
                </div>
                <div class="card">
                    <h3>📂 平台分布</h3>
                    <div id="platform-stats" style="margin-top:10px">加载中...</div>
                </div>
                <div class="card">
                    <h3>⏰ 系统时间</h3>
                    <div class="stat" id="sys-time" style="font-size:1.2em">-</div>
                </div>
            </div>
            
            <div class="card">
                <h3>📋 最近下载</h3>
                <table id="recent-files">
                    <thead><tr><th>文件名</th><th>大小</th><th>修改时间</th></tr></thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
        
        <!-- 文件管理 -->
        <div id="files" class="section">
            <div class="card">
                <h3>📁 文件目录</h3>
                <div class="tree" id="file-tree">加载中...</div>
                <div style="margin-top:15px">
                    <button class="btn btn-primary" onclick="runOrganize()">🗂️ 整理文件</button>
                    <button class="btn btn-success" onclick="runNfoGen()">📝 生成 NFO</button>
                </div>
            </div>
        </div>
        
        <!-- 任务队列 -->
        <div id="tasks" class="section">
            <div class="card">
                <h3>📋 下载队列</h3>
                <table id="task-list">
                    <thead><tr><th>文件名</th><th>状态</th><th>进度</th></tr></thead>
                    <tbody></tbody>
                </table>
            </div>
        </div>
        
        <!-- 配置 -->
        <div id="config" class="section">
            <div class="card">
                <h3>⚙️ 通知配置</h3>
                <form id="config-form">
                    <div class="form-group">
                        <label>Telegram Bot Token</label>
                        <input type="text" name="TELEGRAM_BOT_TOKEN" placeholder="123456:ABC-DEF...">
                    </div>
                    <div class="form-group">
                        <label>Telegram Chat ID</label>
                        <input type="text" name="TELEGRAM_CHAT_ID" placeholder="-1001234567890">
                    </div>
                    <div class="form-group">
                        <label>Server酱 Key</label>
                        <input type="text" name="SERVERCHAN_KEY" placeholder="SCT..."
                    </div>
                    <div class="form-group">
                        <label>PushPlus Token</label>
                        <input type="text" name="PUSHPLUS_TOKEN" placeholder="...">
                    </div>
                    <button type="submit" class="btn btn-primary">保存配置</button>
                </form>
            </div>
            
            <div class="card" style="margin-top:20px">
                <h3>🌐 代理配置</h3>
                <div class="form-group">
                    <label>HTTP 代理</label>
                    <input type="text" id="http-proxy" placeholder="http://192.168.5.9:7890">
                </div>
                <button class="btn btn-primary" onclick="saveProxy()">保存代理</button>
            </div>
        </div>
        
        <!-- 日志 -->
        <div id="logs" class="section">
            <div class="card">
                <h3>📝 系统日志</h3>
                <pre id="log-content" style="max-height:500px;overflow:auto;background:#0f172a;padding:15px;border-radius:8px;font-size:0.85em;line-height:1.6">加载中...</pre>
                <button class="btn btn-primary" onclick="refreshLogs()" style="margin-top:10px">🔄 刷新</button>
            </div>
        </div>
    </div>
    
    <button class="refresh-btn" onclick="refreshAll()">🔄</button>
    
    <script>
        function showSection(name) {
            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            document.getElementById(name).classList.add('active');
            event.target.classList.add('active');
        }
        
        async function refreshAll() {
            const res = await fetch('/api/stats');
            const data = await res.json();
            document.getElementById('total-files').textContent = data.total_files;
            document.getElementById('total-size').textContent = data.total_size;
            document.getElementById('sys-time').textContent = data.time;
            
            if (data.platforms) {
                let html = '';
                for (const [k,v] of Object.entries(data.platforms)) {
                    html += `<div><span class="badge badge-info">${k}</span> ${v} 个</div>`;
                }
                document.getElementById('platform-stats').innerHTML = html || '<div style="color:#94a3b8">暂无数据</div>';
            }
        }
        
        async function refreshLogs() {
            const res = await fetch('/api/logs');
            const data = await res.json();
            document.getElementById('log-content').textContent = data.logs || '暂无日志';
        }
        
        async function refreshFiles() {
            const res = await fetch('/api/files');
            const data = await res.json();
            document.getElementById('file-tree').innerHTML = data.tree || '<div style="color:#94a3b8">暂无文件</div>';
        }
        
        function runOrganize() {
            if (confirm('确定要整理下载文件吗？')) {
                fetch('/api/organize', {method: 'POST'}).then(r => r.json()).then(d => {
                    alert(d.message);
                    refreshFiles();
                });
            }
        }
        
        function runNfoGen() {
            if (confirm('确定要生成 NFO 元数据吗？')) {
                fetch('/api/nfo-gen', {method: 'POST'}).then(r => r.json()).then(d => {
                    alert(d.message);
                    refreshFiles();
                });
            }
        }
        
        document.getElementById('config-form').addEventListener('submit', function(e) {
            e.preventDefault();
            const data = Object.fromEntries(new FormData(this));
            fetch('/api/config', {method: 'POST', headers: {'Content-Type':'application/json'}, body: JSON.stringify(data)})
                .then(r => r.json()).then(d => alert(d.message));
        });
        
        // 初始化
        refreshAll();
        refreshFiles();
        refreshLogs();
        setInterval(refreshAll, 30000);
    </script>
</body>
</html>
'''

# ===== API 路由 =====
@app.route('/')
def index():
    return render_template_string(TEMPLATE)

@app.route('/api/stats')
def api_stats():
    stats = {
        'total_files': 0,
        'total_size': '0 B',
        'platforms': {},
        'time': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    }
    
    total_bytes = 0
    platform_counts = {}
    
    for root, dirs, files in os.walk(DOWNLOAD_DIR):
        for f in files:
            filepath = os.path.join(root, f)
            try:
                size = os.path.getsize(filepath)
                total_bytes += size
                stats['total_files'] += 1
                
                # 统计平台
                rel_path = os.path.relpath(filepath, DOWNLOAD_DIR)
                platform = rel_path.split(os.sep)[0] if os.sep in rel_path else 'unknown'
                platform_counts[platform] = platform_counts.get(platform, 0) + 1
            except:
                pass
    
    stats['platforms'] = platform_counts
    
    # 格式化大小
    for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
        if total_bytes < 1024:
            stats['total_size'] = f"{total_bytes:.1f} {unit}"
            break
        total_bytes /= 1024
    
    return jsonify(stats)

@app.route('/api/files')
def api_files():
    tree = '<div class="tree-item tree-folder">📁 downloads/</div>'
    
    for platform in sorted(os.listdir(DOWNLOAD_DIR)):
        platform_path = os.path.join(DOWNLOAD_DIR, platform)
        if os.path.isdir(platform_path):
            tree += f'<div class="tree-item" style="padding-left:20px"><span class="tree-folder">📂 {platform}/</span></div>'
            
            for creator in sorted(os.listdir(platform_path))[:5]:
                creator_path = os.path.join(platform_path, creator)
                if os.path.isdir(creator_path):
                    tree += f'<div class="tree-item" style="padding-left:40px"><span class="tree-folder">👤 {creator}/</span></div>'
    
    return jsonify({'tree': tree})

@app.route('/api/organize', methods=['POST'])
def api_organize():
    try:
        result = subprocess.run(['bash', '/app/scripts/organize.sh'], 
                              capture_output=True, text=True, timeout=60)
        return jsonify({'success': True, 'message': '文件整理完成'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'整理失败: {str(e)}'})

@app.route('/api/nfo-gen', methods=['POST'])
def api_nfo_gen():
    try:
        result = subprocess.run(['bash', '/app/scripts/nfo-gen.sh'],
                              capture_output=True, text=True, timeout=60)
        return jsonify({'success': True, 'message': 'NFO 生成完成'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'生成失败: {str(e)}'})

@app.route('/api/config', methods=['POST'])
def api_config():
    try:
        data = request.json
        config_file = os.path.join(CONFIG_DIR, '.env')
        
        lines = []
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                lines = f.readlines()
        
        for key, value in data.items():
            found = False
            for i, line in enumerate(lines):
                if line.startswith(f'{key}='):
                    lines[i] = f'{key}={value}\n'
                    found = True
                    break
            if not found:
                lines.append(f'{key}={value}\n')
        
        with open(config_file, 'w') as f:
            f.writelines(lines)
        
        return jsonify({'success': True, 'message': '配置已保存'})
    except Exception as e:
        return jsonify({'success': False, 'message': f'保存失败: {str(e)}'})

@app.route('/api/logs')
def api_logs():
    log_file = os.path.join(LOG_DIR, 'streamvault.log')
    if os.path.exists(log_file):
        with open(log_file, 'r') as f:
            lines = f.readlines()[-100:]  # 最后100行
            return jsonify({'logs': ''.join(lines)})
    return jsonify({'logs': '暂无日志'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=28082, debug=False)
