/**
 * 云端AI核查引擎 - 第2层核实
 * 调用LLM API进行深度语义分析和多信源交叉验证
 */
import { CloudCheckResult, FactSource, RiskLevel } from './Types';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'CloudCheckEngine';

// 权威信源白名单
const AUTHORITY_SOURCES: Record<string, string> = {
  'nhc': '国家卫健委',
  'gov': '中国政府网',
  'pbc': '中国人民银行',
  'cbirc': '国家金融监管总局',
  'xinhua': '新华社',
  'people': '人民日报',
  'cctv': '央视新闻'
};

export class CloudCheckEngine {
  private static instance: CloudCheckEngine;

  static getInstance(): CloudCheckEngine {
    if (!CloudCheckEngine.instance) {
      CloudCheckEngine.instance = new CloudCheckEngine();
    }
    return CloudCheckEngine.instance;
  }

  /**
   * 深度AI核查：调用LLM进行内容真实性验证
   * @param text 待核查文本
   * @param category 初步分类
   * @param timeout 超时时间(ms)，默认3000ms
   */
  async deepCheck(text: string, category: string, timeout: number = 3000): Promise<CloudCheckResult> {
    hilog.info(0x0000, TAG, `Starting deep check, category: ${category}`);

    try {
      // 构建核查 Prompt
      const prompt = this.buildCheckPrompt(text, category);

      // 调用LLM API（此处以通用OpenAI兼容接口为例）
      const response = await this.callLLMAPI(prompt, timeout);

      // 解析返回结果
      return this.parseResponse(response, text);
    } catch (err) {
      hilog.error(0x0000, TAG, `Deep check failed: ${JSON.stringify(err)}`);

      // 降级：超时或失败时返回保守结果
      return {
        score: 50,
        riskLevel: RiskLevel.MEDIUM,
        summary: '云端核查暂不可用，建议谨慎对待该信息。基于本地规则，该内容存在可疑特征。',
        sources: [],
        correctedInfo: ''
      };
    }
  }

  /**
   * 构建核查Prompt
   */
  private buildCheckPrompt(text: string, category: string): string {
    return `你是一个专业的事实核查助手。请对以下内容进行真实性判断。

【内容】
${text}

【核查类别】${category}

【要求】
1. 给出可信度评分（0-100，0=完全虚假，100=完全真实）
2. 逐条指出不实之处（如有）
3. 提供权威信源引用（如卫健委、政府官网、权威媒体）
4. 给出正确的信息（如有）
5. 建议操作（可分享/谨慎分享/不要分享/诈骗举报）

【重要】只核查事实陈述，不判断观点和立场。如果内容同时包含事实和观点，只核查事实部分。

请用以下JSON格式回复：
{
  "score": <0-100>,
  "summary": "<一句话总结>",
  "items": [
    {"claim": "<原主张>", "verdict": "<真实/部分真实/虚假/无法核实>", "correction": "<正确信息>", "source": "<来源名称>", "sourceUrl": "<来源链接>"}
  ],
  "suggestion": "<建议>"
}`;
  }

  /**
   * 调用LLM API
   */
  private async callLLMAPI(prompt: string, timeout: number): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      const httpRequest = http.createHttp();
      const timer = setTimeout(() => {
        httpRequest.destroy();
        reject(new Error('LLM API timeout'));
      }, timeout);

      // 使用通用的OpenAI兼容接口格式
      // 实际项目中替换为华为盘古API或国内大模型API
      const apiUrl = 'https://api.openai.com/v1/chat/completions';
      const apiKey = 'YOUR_API_KEY'; // TODO: 从安全存储读取

      httpRequest.request(apiUrl, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        extraData: JSON.stringify({
          model: 'gpt-4o-mini', // 使用低成本模型
          messages: [
            { role: 'system', content: '你是一个事实核查AI，用中文回复，输出严格JSON。' },
            { role: 'user', content: prompt }
          ],
          temperature: 0.1,
          max_tokens: 800
        }),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeout,
        readTimeout: timeout
      }, (err, data) => {
        clearTimeout(timer);
        if (err) {
          reject(err);
        } else {
          try {
            const json = JSON.parse(data.result as string);
            resolve(json.choices?.[0]?.message?.content || '');
          } catch (e) {
            reject(e);
          }
        }
      });
    });
  }

  /**
   * 解析LLM返回的核查结果
   */
  private parseResponse(response: string, originalText: string): CloudCheckResult {
    try {
      const result = JSON.parse(response);
      const score = Math.max(0, Math.min(100, result.score || 50));

      let riskLevel: RiskLevel;
      if (score >= 80) riskLevel = RiskLevel.SAFE;
      else if (score >= 60) riskLevel = RiskLevel.LOW;
      else if (score >= 40) riskLevel = RiskLevel.MEDIUM;
      else if (score >= 20) riskLevel = RiskLevel.HIGH;
      else riskLevel = RiskLevel.CRITICAL;

      const sources: FactSource[] = (result.items || []).map((item: Record<string, string>) => ({
        name: item.source || '未知来源',
        url: item.sourceUrl || '',
        quote: item.verdict || '',
        date: new Date().toISOString().split('T')[0]
      }));

      const corrections = (result.items || [])
        .filter((item: Record<string, string>) => item.correction)
        .map((item: Record<string, string>) => item.correction)
        .join('；');

      return {
        score,
        riskLevel,
        summary: result.summary || `可信度评分：${score}分`,
        sources,
        correctedInfo: corrections || ''
      };
    } catch (e) {
      // JSON解析失败，返回原始回复
      return {
        score: 50,
        riskLevel: RiskLevel.MEDIUM,
        summary: response.substring(0, 200),
        sources: [],
        correctedInfo: ''
      };
    }
  }
}