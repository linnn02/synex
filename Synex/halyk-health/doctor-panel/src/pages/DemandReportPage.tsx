import { useEffect, useState } from "react";
import { 
  BarChart3, 
  TrendingUp, 
  AlertTriangle, 
  PackageSearch, 
  Lightbulb, 
  ArrowRight,
  RefreshCw
} from "lucide-react";
import { api } from "../api/api";

type DemandReport = {
  frequentlyPrescribed: string[];
  cartLeaders: string[];
  outOfStockDemand: string[];
  popularAlternatives: string[];
  demandForecast: string;
  businessSummary: string;
};

export function DemandReportPage() {
  const [report, setReport] = useState<DemandReport | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const loadReport = async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.getDemandReport();
      setReport(data);
    } catch (e) {
      setError("Не удалось загрузить аналитический отчет.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReport();
  }, []);

  if (loading) {
    return (
      <div className="demand-loading">
        <RefreshCw className="spinner" size={32} />
        <p>AI-агент анализирует рынок и назначения...</p>
      </div>
    );
  }

  if (error || !report) {
    return <div className="error-panel">{error}</div>;
  }

  return (
    <div className="demand-report-container">
      <header className="report-header">
        <div>
          <h1>AI Аналитика спроса</h1>
          <p>Интеллектуальный отчет по назначениям и рыночному спросу B2B</p>
        </div>
        <button className="secondary-button" onClick={loadReport}>
          <RefreshCw size={18} />
          Обновить
        </button>
      </header>

      <div className="report-summary-card">
        <div className="summary-icon"><Lightbulb size={24} /></div>
        <div className="summary-content">
          <h3>Краткий вывод AI</h3>
          <p>{report.businessSummary}</p>
        </div>
      </div>

      <div className="report-grid">
        <section className="report-section">
          <div className="section-head">
            <BarChart3 size={20} />
            <h2>Популярные назначения</h2>
          </div>
          <div className="item-list">
            {report.frequentlyPrescribed.map((item, i) => (
              <div key={i} className="report-item">
                <span>{item}</span>
                <TrendingUp size={14} className="trend-up" />
              </div>
            ))}
          </div>
        </section>

        <section className="report-section">
          <div className="section-head">
            <PackageSearch size={20} />
            <h2>Лидеры корзин</h2>
          </div>
          <div className="item-list">
            {report.cartLeaders.map((item, i) => (
              <div key={i} className="report-item">
                <span>{item}</span>
                <ArrowRight size={14} />
              </div>
            ))}
          </div>
        </section>

        <section className="report-section danger">
          <div className="section-head">
            <AlertTriangle size={20} />
            <h2>Дефицит (Out of Stock)</h2>
          </div>
          <div className="item-list">
            {report.outOfStockDemand.map((item, i) => (
              <div key={i} className="report-item danger">
                <span>{item}</span>
                <small>Высокий спрос</small>
              </div>
            ))}
          </div>
        </section>

        <section className="report-section info">
          <div className="section-head">
            <TrendingUp size={20} />
            <h2>Популярные аналоги</h2>
          </div>
          <div className="item-list">
            {report.popularAlternatives.map((item, i) => (
              <div key={i} className="report-item info">
                <span>{item}</span>
              </div>
            ))}
          </div>
        </section>
      </div>

      <div className="forecast-box">
        <h3><SparklesIcon /> Прогноз спроса на неделю</h3>
        <p>{report.demandForecast}</p>
      </div>
    </div>
  );
}

function SparklesIcon() {
  return <TrendingUp className="sparkle-icon" size={20} />;
}
