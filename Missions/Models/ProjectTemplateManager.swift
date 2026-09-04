import Foundation
import SwiftData

struct TemplateStep {
    let title: String
}

struct TemplateMission {
    let title: String
    let details: String
    let priority: Priority
    let phase: String
    let steps: [TemplateStep]
}

struct ProjectTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let category: String
    let missions: [TemplateMission]
}

class ProjectTemplateManager {
    static let shared = ProjectTemplateManager()
    
    let templates: [ProjectTemplate] = [
        ProjectTemplate(
            name: "Viagem & Férias Sem Estresse",
            icon: "airplane.circle.fill",
            description: "Checklist operacional completo para voos, hotel, malas e cartões.",
            category: "Pessoal & Lazer",
            missions: [
                TemplateMission(
                    title: "Reservar Hospedagem e Voos",
                    details: "Garantir reservas com antecedência para obter melhores preços.",
                    priority: .high,
                    phase: "Fase 1: Reservas",
                    steps: [
                        TemplateStep(title: "Comprar passagens aéreas / passagens de ônibus"),
                        TemplateStep(title: "Reservar hotel ou hospedagem Airbnb"),
                        TemplateStep(title: "Confirmar horários de check-in e check-out")
                    ]
                ),
                TemplateMission(
                    title: "Documentação e Cartões",
                    details: "Evitar bloqueios ou imprevistos durante o deslocamento.",
                    priority: .high,
                    phase: "Fase 1: Reservas",
                    steps: [
                        TemplateStep(title: "Verificar validade do Passaporte / RG"),
                        TemplateStep(title: "Contratar seguro viagem"),
                        TemplateStep(title: "Ativar aviso de viagem nos cartões de crédito")
                    ]
                ),
                TemplateMission(
                    title: "Organizar Malas e Bagagem",
                    details: "Montar mala funcional de acordo com o clima do destino.",
                    priority: .medium,
                    phase: "Fase 2: Preparação",
                    steps: [
                        TemplateStep(title: "Separar roupas adequadas ao clima"),
                        TemplateStep(title: "Montar kit de remédios essenciais e higiene"),
                        TemplateStep(title: "Carregadores, adaptadores de tomada e powerbank")
                    ]
                )
            ]
        ),
        
        ProjectTemplate(
            name: "Reforma / Obra / Manutenção",
            icon: "hammer.circle.fill",
            description: "Controle de fornecedores, materiais, prazos e custos.",
            category: "Casa & Infraestrutura",
            missions: [
                TemplateMission(
                    title: "Planejamento e Orçamentos",
                    details: "Comparar preços e definir limites de gastos.",
                    priority: .high,
                    phase: "Fase 1: Orçamento",
                    steps: [
                        TemplateStep(title: "Cotar orçamento com 3 pedreiros / prestadores"),
                        TemplateStep(title: "Montar lista de materiais com preço estimado"),
                        TemplateStep(title: "Definir teto máximo do orçamento do projeto")
                    ]
                ),
                TemplateMission(
                    title: "Compra e Entrega de Materiais",
                    details: "Garantir insumos no local antes do início do trabalho.",
                    priority: .high,
                    phase: "Fase 2: Compra",
                    steps: [
                        TemplateStep(title: "Comprar materiais brutos (cimento, tintas, azulejos)"),
                        TemplateStep(title: "Agendar data exata de entrega na obra"),
                        TemplateStep(title: "Guardar todas as notas fiscais para garantia")
                    ]
                ),
                TemplateMission(
                    title: "Execução e Vistoria",
                    details: "Acompanhar andamento e realizar pagamentos por etapas.",
                    priority: .medium,
                    phase: "Fase 3: Execução",
                    steps: [
                        TemplateStep(title: "Vistoriar progresso diário do trabalho"),
                        TemplateStep(title: "Agendar caçamba para remoção de entulho"),
                        TemplateStep(title: "Fazer pagamento final apenas após aprovação")
                    ]
                )
            ]
        ),
        
        ProjectTemplate(
            name: "Lançamento de Produto / Campanha",
            icon: "rocket.circle.fill",
            description: "Passo a passo estratégico de vendas, design e divulgação.",
            category: "Trabalho & Negócios",
            missions: [
                TemplateMission(
                    title: "Estratégia e Conteúdo",
                    details: "Criar narrativa e oferta principal do lançamento.",
                    priority: .high,
                    phase: "Fase 1: Planejamento",
                    steps: [
                        TemplateStep(title: "Escrever briefing e oferta irresistível do produto"),
                        TemplateStep(title: "Definir meta de faturamento / unidades"),
                        TemplateStep(title: "Redigir cópias para e-mails e anúncios")
                    ]
                ),
                TemplateMission(
                    title: "Design e Página de Vendas",
                    details: "Produção de artes e estrutura de conversão.",
                    priority: .high,
                    phase: "Fase 2: Produção",
                    steps: [
                        TemplateStep(title: "Criar banners e criativos para redes sociais"),
                        TemplateStep(title: "Gravar e editar vídeos de apresentação"),
                        TemplateStep(title: "Aprovar Landing Page e checkout de pagamento")
                    ]
                ),
                TemplateMission(
                    title: "Abertura de Carrinho / Lançamento",
                    details: "Execução e monitoramento de resultados.",
                    priority: .high,
                    phase: "Fase 3: Lançamento",
                    steps: [
                        TemplateStep(title: "Disparar e-mail de abertura para a lista"),
                        TemplateStep(title: "Ativar campanhas de tráfego pago"),
                        TemplateStep(title: "Acompanhar suporte ao cliente e tirar dúvidas")
                    ]
                )
            ]
        ),
        
        ProjectTemplate(
            name: "Organização Financeira Mensal",
            icon: "dollarsign.circle.fill",
            description: "Revisão de cartão de crédito, contas fixas e aportes.",
            category: "Finanças",
            missions: [
                TemplateMission(
                    title: "Auditoria de Contas e Gastos",
                    details: "Mapear para onde o dinheiro foi no mês anterior.",
                    priority: .high,
                    phase: "Fase 1: Diagnóstico",
                    steps: [
                        TemplateStep(title: "Conferir fatura do cartão de crédito linha por linha"),
                        TemplateStep(title: "Cancelar assinaturas que não está utilizando"),
                        TemplateStep(title: "Categorizar despesas fixas vs variáveis")
                    ]
                ),
                TemplateMission(
                    title: "Aportes e Reservas",
                    details: "Separar primeiro o dinheiro do seu futuro.",
                    priority: .high,
                    phase: "Fase 2: Investimentos",
                    steps: [
                        TemplateStep(title: "Transferir percentual para Reserva de Emergência"),
                        TemplateStep(title: "Realizar aporte nos investimentos de longo prazo"),
                        TemplateStep(title: "Definir teto de gastos disponíveis para este mês")
                    ]
                )
            ]
        ),
        
        ProjectTemplate(
            name: "Estudo / Curso / Certificação",
            icon: "book.circle.fill",
            description: "Estrutura para concluir cursos e certificações sem procrastinar.",
            category: "Educação & Carreira",
            missions: [
                TemplateMission(
                    title: "Mapeamento do Curso",
                    details: "Planejar a carga horária e módulos.",
                    priority: .medium,
                    phase: "Fase 1: Organização",
                    steps: [
                        TemplateStep(title: "Mapear total de módulos e quantidade de aulas"),
                        TemplateStep(title: "Bloquear 1h diária na agenda para assistir aulas"),
                        TemplateStep(title: "Criar caderno virtual ou físico para anotações")
                    ]
                ),
                TemplateMission(
                    title: "Exercícios e Revisão",
                    details: "Fixar conhecimento na memória de longo prazo.",
                    priority: .high,
                    phase: "Fase 2: Execução",
                    steps: [
                        TemplateStep(title: "Resolver exercícios práticos do módulo"),
                        TemplateStep(title: "Fazer resumos visuais de cada capítulo"),
                        TemplateStep(title: "Realizar simulados ou projeto final")
                    ]
                )
            ]
        )
    ]
    
    func applyTemplate(_ template: ProjectTemplate, to project: Project, in modelContext: ModelContext) {
        for (mIndex, tMission) in template.missions.enumerated() {
            let mission = Mission(
                title: tMission.title,
                details: tMission.details,
                priority: tMission.priority,
                phase: tMission.phase
            )
            mission.project = project
            modelContext.insert(mission)
            
            for (sIndex, tStep) in tMission.steps.enumerated() {
                let step = Step(title: tStep.title, order: sIndex)
                step.mission = mission
                modelContext.insert(step)
            }
        }
        
        try? modelContext.save()
    }
}
