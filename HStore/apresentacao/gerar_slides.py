import sys,json
from pathlib import Path
sys.path.insert(0,'/private/tmp/hstore_pptx_lib')
from pptx import Presentation
from pptx.util import Inches,Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
R=Presentation();R.slide_width=Inches(13.333);R.slide_height=Inches(7.5)
BG='#101B2C'; WHITE='#F4F7FC';MUTED='#B7C5D8';ACC='#53D6BE';PANEL='#1C2C43'
def rgb(c):return RGBColor.from_string(c.strip('#'))
def box(s,x,y,w,h,color):
 sh=s.shapes.add_shape(MSO_SHAPE.RECTANGLE, Inches(x), Inches(y), Inches(w), Inches(h));sh.fill.solid();sh.fill.fore_color.rgb=rgb(color);sh.line.fill.background();return sh
def txt(s,x,y,w,h,text,size=22,color=WHITE,font='Aptos',bold=False):
 sh=s.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h));tf=sh.text_frame;tf.word_wrap=True
 for i,line in enumerate(text.split('\n')):
  p=tf.paragraphs[0] if i==0 else tf.add_paragraph();p.text=line;p.font.name=font;p.font.size=Pt(size);p.font.bold=bold;p.font.color.rgb=rgb(color);p.space_after=Pt(12)
 return sh
def slide(title,sub=''):
 s=R.slides.add_slide(R.slide_layouts[6]);s.background.fill.solid();s.background.fill.fore_color.rgb=rgb(BG)
 box(s,.55,.5,.6,.06,ACC);txt(s,.65,.8,12, .65,title,30,bold=True)
 if sub:txt(s,.65,1.55,12,.6,sub,17,MUTED)
 txt(s,.65,7.05,10,.25,'ALUNOS80K  /  HSTORE  /  RESOLUÇÃO DO EXERCÍCIO',10,MUTED)
 txt(s,12,7.02,.65,.3,f'{len(R.slides):02}',11,ACC)
 return s
def code(s,text,y=2.3,h=3.9,size=19):
 box(s,.65,y,12,h,PANEL);txt(s,.9,y+.18,11.5,h-.25,text,size,WHITE,'Menlo')
def note(s,text):s.notes_slide.notes_text_frame.text=text
s=slide('Destaques acadêmicos com HStore','Resolução do exercício • PostgreSQL • Base Alunos80K')
txt(s,.7,2.6,11.6,1.5,'De notas e frequência\na pares chave–valor por aluno',38,bold=True)
txt(s,.7,5.1,11.6,.8,'Distinção   /   Trancamento   /   Bom',24,ACC)
note(s,'Apresentar o objetivo: enriquecer Configura com informações acadêmicas derivadas das matrículas, preservando as configurações existentes.')
s=slide('O que o exercício pede','Adicionar Destaques, do tipo hstore, à tabela Configura.')
items=[('Distinção','Alguma NF ≥ 9','Guardar a maior NF entre aprovações (NF > 5).'),('Trancamento','Frequência = 0 e NF ≤ 0,5','Guardar o código da disciplina.'),('Bom','Ao menos 2 disciplinas com NF ≥ 8','Guardar a quantidade de disciplinas.')]
for i,(a,b,c) in enumerate(items):
 y=2.35+i*1.35;box(s,.65,y,12,1.15,PANEL);txt(s,.9,y+.15,2.3,.7,a,23,ACC, bold=True);txt(s,3.3,y+.1,8.9,.45,b,22,bold=True);txt(s,3.3,y+.58,8.9,.45,c,17,MUTED)
note(s,'O enunciado permite assumir Destaques vazio no primeiro passo, mas exige preservar as chaves nos passos seguintes. Para múltiplos trancamentos, guardamos todos os códigos num único texto.')
s=slide('Preparação e origem dos dados','Primeiro a base; depois a tabela de configurações; por fim o exercício.')
for i,(a,b) in enumerate([('01  Gerar a base','S1.2 + Tudo.sql → alunos80k, com 80 mil alunos.'),('02  Preparar HStore','7.1 → extensão hstore + 40 mil registros em Configura.'),('03  Aplicar os destaques','Matricula + Turma → notas_atividade → Configura.Destaques.')]):
 y=2.4+i*1.25;txt(s,.8,y,11.8,.45,a,24,ACC,bold=True);txt(s,.8,y+.5,11.8,.55,b,21)
note(s,'Os notebooks têm funções diferentes: o primeiro gera a base; o segundo prepara Configura; os scripts SQL resolvem a tarefa. Não reexecutar a preparação após a resolução, pois ela recria Configura.')
s=slide('Uma origem comum para os três critérios','O código da turma conecta cada matrícula à sigla da disciplina.')
code(s,Path('sql/01_origem.sql').read_text().split('\n',1)[1],size=20)
note(s,'Matricula contém NUSP, NF e Frequencia. Turma traduz CodigoTurma para Sigla. A view é temporária e precisa ser usada na mesma conexão que executa a resolução.')
s=slide('1 / Distinção','Agrupar por aluno e selecionar quem tem pelo menos uma NF ≥ 9.')
code(s,"SELECT a.NUSP, a.Nome, max(n.nf)::text AS valor\nFROM Alunos a JOIN notas_atividade n\n  ON n.nusp = a.NUSP\nWHERE n.nf > 5\nGROUP BY a.NUSP, a.Nome\nHAVING max(n.nf) >= 9;",size=21)
note(s,'A maior nota é o valor da chave Distinção. HAVING seleciona os alunos após a agregação. Exemplo ilustrativo: notas 7, 9 e 9,5 geram Distinção = 9,5.')
s=slide('2 / Trancamento','As duas condições devem ocorrer na mesma matrícula.')
code(s,"SELECT a.NUSP, a.Nome,\n  string_agg(DISTINCT n.disciplina, ', '\n             ORDER BY n.disciplina) AS valor\nFROM Alunos a JOIN notas_atividade n\n  ON n.nusp = a.NUSP\nWHERE n.frequencia = 0 AND n.nf <= 0.5\nGROUP BY a.NUSP, a.Nome;",size=19)
note(s,'Para não perder disciplinas quando existe mais de um trancamento, string_agg reúne os códigos em um valor textual. DISTINCT evita códigos repetidos.')
s=slide('3 / Bom','Contar disciplinas distintas com nota final de pelo menos 8.')
code(s,"SELECT a.NUSP, a.Nome,\n  count(DISTINCT n.disciplina)::text AS valor\nFROM Alunos a JOIN notas_atividade n\n  ON n.nusp = a.NUSP\nWHERE n.nf >= 8\nGROUP BY a.NUSP, a.Nome\nHAVING count(DISTINCT n.disciplina) >= 2;",size=20)
note(s,'Usamos disciplinas distintas para que duas matrículas da mesma disciplina não sejam contadas como duas disciplinas. O resultado é convertido para texto porque os valores de hstore são textuais.')
s=slide('Atualizar existentes e inserir novos','A instalação utilizada não aceita MERGE; a solução usa UPDATE + INSERT.')
code(s,"WITH origem AS ( /* consulta de cada critério */ ),\natualizados AS (\n  UPDATE Configura c\n  SET Destaques = coalesce(c.Destaques, ''::hstore)\n                 || hstore('Distinção', s.valor)\n  FROM origem s WHERE c.NUSP = s.NUSP\n  RETURNING c.NUSP\n)\nINSERT INTO Configura (NUSP, Nome, Destaques)\nSELECT s.NUSP, s.Nome, hstore('Distinção', s.valor)\nFROM origem s\nWHERE NOT EXISTS (SELECT 1 FROM Configura c\n                  WHERE c.NUSP = s.NUSP);",h=4.4,size=15)
note(s,'Padrão real usado nos três passos. Origem deve retornar uma linha por aluno. COALESCE trata NULL e || acrescenta a chave sem apagar as anteriores. O INSERT atende alunos que ainda não existiam em Configura, levando também o Nome. A coluna Config não é alterada. BEGIN e COMMIT abrangem as três etapas.')
d=json.loads(Path('apresentacao/resultados.json').read_text())
s=slide('Resultados da execução','Contagens consultadas no banco alunos80k após a aplicação da resolução.')
for i,(k,label) in enumerate([('distincao','Distinção'),('trancamento','Trancamento'),('bom','Bom')]):
 x=.65+i*4.08;box(s,x,2.4,3.85,2.1,PANEL);txt(s,x+.2,2.65,3.4,.9,str(d[k]),50,ACC,bold=True);txt(s,x+.2,3.7,3.4,.5,label,23)
txt(s,.8,4.95,11.8,.6,f"{d['total']:,}".replace(',','.')+' registros em Configura após a resolução.',26,bold=True)
txt(s,.8,5.7,11.8,.9,'Nenhum aluno atendeu ao critério Bom nesta base gerada.\nAs contagens de chaves podem se sobrepor.',19,MUTED)
note(s,'A preparação tinha 40.000 registros; a resolução acrescentou 156 alunos, totalizando 40.156. INSERT 0 0 não significa erro: pode haver atualizações sem novas inserções. Não confundir número de inserções com total de alunos que possuem a chave. Dados sintéticos podem variar entre gerações.')
s=slide('O que a solução entrega','As três regras aplicadas, com os dados anteriores preservados.')
txt(s,.8,2.4,11.7,2.8,'• Destaques adicionado como hstore.\n• Atualização por NUSP e inserção com Nome.\n• Chaves acumuladas com COALESCE e ||.\n• Config original preservado.\n• Execução concluída com COMMIT.',25)
txt(s,.8,5.55,11.8,.7,'Scripts: 01_origem.sql → 02_resolucao.sql → 03_conferir.sql',18,ACC)
note(s,'Fontes: enunciado do professor, slides 86 a 88 fornecidos na conversa; notebooks S1.2 e 7.1; scripts SQL do projeto. A resolução é reexecutável com a mesma origem. Se as notas mudarem, ela não remove automaticamente chaves de quem deixar de atender ao critério. Os trechos SQL dos slides mostram a lógica; o arquivo 02_resolucao.sql contém os três blocos completos.')
R.save('apresentacao/Resolucao_HStore_Alunos80K.pptx')
assert len(R.slides)==10
for i,s in enumerate(R.slides,1):
 for sh in s.shapes:
  assert sh.left>=0 and sh.top>=0
  assert sh.left+sh.width<=R.slide_width+10000,(i,'largura')
  assert sh.top+sh.height<=R.slide_height+10000,(i,'altura')
print('PPTX criado e validado: 10 slides, com notas de apresentação.')
