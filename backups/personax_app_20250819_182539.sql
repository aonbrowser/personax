--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)
-- Dumped by pg_dump version 14.18 (Ubuntu 14.18-0ubuntu0.22.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: assessments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assessments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    person_id uuid NOT NULL,
    type text,
    version text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT assessments_type_check CHECK ((type = ANY (ARRAY['S1'::text, 'S2'::text, 'S3'::text, 'S4'::text])))
);


ALTER TABLE public.assessments OWNER TO postgres;

--
-- Name: chat_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chat_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dyad_id uuid NOT NULL,
    metadata jsonb
);


ALTER TABLE public.chat_sessions OWNER TO postgres;

--
-- Name: dyad_scores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dyad_scores (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    dyad_id uuid NOT NULL,
    compatibility_score real,
    strengths_json jsonb,
    risks_json jsonb,
    plan_json jsonb,
    confidence real
);


ALTER TABLE public.dyad_scores OWNER TO postgres;

--
-- Name: dyads; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dyads (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    a_person_id uuid NOT NULL,
    b_person_id uuid NOT NULL,
    relation_type text NOT NULL
);


ALTER TABLE public.dyads OWNER TO postgres;

--
-- Name: items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items (
    id text NOT NULL,
    form text,
    section text,
    subscale text,
    text_tr text,
    type text,
    options_tr text,
    reverse_scored integer DEFAULT 0,
    scoring_key text,
    weight real DEFAULT 1.0,
    notes text,
    display_order integer
);


ALTER TABLE public.items OWNER TO postgres;

--
-- Name: language_incidents; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.language_incidents (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    report_type text,
    user_language text NOT NULL,
    detected_language text NOT NULL,
    content_preview text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT language_incidents_report_type_check CHECK ((report_type = ANY (ARRAY['self'::text, 'other'::text, 'dyad'::text, 'coach'::text])))
);


ALTER TABLE public.language_incidents OWNER TO postgres;

--
-- Name: messages; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.messages (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    session_id uuid NOT NULL,
    role text,
    content text,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT messages_role_check CHECK ((role = ANY (ARRAY['user'::text, 'assistant'::text, 'system'::text])))
);


ALTER TABLE public.messages OWNER TO postgres;

--
-- Name: people; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.people (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    label text NOT NULL,
    relation_type text NOT NULL,
    gender text,
    age integer,
    notes text
);


ALTER TABLE public.people OWNER TO postgres;

--
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    owner_user_id uuid NOT NULL,
    dyad_id uuid NOT NULL,
    markdown text,
    version text
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- Name: responses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.responses (
    id bigint NOT NULL,
    assessment_id uuid NOT NULL,
    item_id text NOT NULL,
    value text NOT NULL,
    rt_ms integer
);


ALTER TABLE public.responses OWNER TO postgres;

--
-- Name: responses_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.responses_id_seq OWNER TO postgres;

--
-- Name: responses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.responses_id_seq OWNED BY public.responses.id;


--
-- Name: scores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scores (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    assessment_id uuid NOT NULL,
    bigfive_json jsonb,
    mbti_json jsonb,
    enneagram_json jsonb,
    attachment_json jsonb,
    conflict_json jsonb,
    social_json jsonb,
    quality_flags jsonb
);


ALTER TABLE public.scores OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email text,
    locale text,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: responses id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses ALTER COLUMN id SET DEFAULT nextval('public.responses_id_seq'::regclass);


--
-- Data for Name: assessments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assessments (id, person_id, type, version, created_at) FROM stdin;
\.


--
-- Data for Name: chat_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.chat_sessions (id, dyad_id, metadata) FROM stdin;
\.


--
-- Data for Name: dyad_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dyad_scores (id, dyad_id, compatibility_score, strengths_json, risks_json, plan_json, confidence) FROM stdin;
\.


--
-- Data for Name: dyads; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.dyads (id, a_person_id, b_person_id, relation_type) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items (id, form, section, subscale, text_tr, type, options_tr, reverse_scored, scoring_key, weight, notes, display_order) FROM stdin;
S1_BF_E1	S1_self	BigFive	E	Sosyal ortamlarda enerji toplarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_E2	S1_self	BigFive	E	Yeni insanlarla tanışmak beni heyecanlandırır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_E3	S1_self	BigFive	E	Kalabalık etkinlikler beni yorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_E4	S1_self	BigFive	E	Topluluk önünde konuşmaktan keyif alırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A1	S1_self	BigFive	A	İnsanların bakış açısını anlamaya çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A2	S1_self	BigFive	A	Anlaşmazlıklarda empati kurarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A3	S1_self	BigFive	A	Eleştirirken sözlerimi özenle seçerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_A4	S1_self	BigFive	A	Kendi ihtiyaçlarımı her zaman öne koyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_C1	S1_self	BigFive	C	Planları önceden yapar ve takip ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_C2	S1_self	BigFive	C	Detayları gözden kaçırmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_C3	S1_self	BigFive	C	Son dakika işleri severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_C4	S1_self	BigFive	C	Söz verdiğim işi vaktinde bitiririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_N1	S1_self	BigFive	N	Stresliyken kolayca gerginleşirim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_N2	S1_self	BigFive	N	Eleştirilere karşı hassasım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_N3	S1_self	BigFive	N	Zor durumda soğukkanlı kalırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_N4	S1_self	BigFive	N	Gelecek hakkında sık endişe duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_O1	S1_self	BigFive	O	Yeni fikir ve deneyimlere açığım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_O2	S1_self	BigFive	O	Rutini kırmayı severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_BF_O3	S1_self	BigFive	O	Alışılmış yöntemler dışına çıkmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S1_BF_O4	S1_self	BigFive	O	Sanat/yaratıcılık içeren şeylerden keyif alırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_MB_FC1	S1_self	MBTI	EI	A) Kalabalıkta enerji toplarım  |  B) Yalnız kalarak şarj olurum	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	Ipsatif (sosyal beğenirlik azaltma)	\N
S1_MB_FC2	S1_self	MBTI	EI	A) Yeni insanlarla hızla bağ kurarım  |  B) Önce gözlemler sonra açılırım	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	\N	\N
S1_MB_FC3	S1_self	MBTI	EI	A) Yüksek sesli ve hareketli ortamlar beni canlandırır  |  B) Sessiz ve sakin ortamları tercih ederim	ForcedChoice2	A|B	0	{"A":"EI:E","B":"EI:I"}	1	\N	\N
S1_MB_FC4	S1_self	MBTI	SN	A) Gerçekler ve kanıtlar  |  B) Fikirler ve olasılıklar beni daha çok cezbeder	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N
S1_MB_FC5	S1_self	MBTI	SN	A) Detaylara odaklanırım  |  B) Büyük resmi görmeyi tercih ederim	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N
S1_MB_FC6	S1_self	MBTI	SN	A) Mevcut duruma dayanırım  |  B) Gelecekteki potansiyeli merak ederim	ForcedChoice2	A|B	0	{"A":"SN:S","B":"SN:N"}	1	\N	\N
S1_MB_FC7	S1_self	MBTI	TF	A) Kararda tutarlılık ve mantık  |  B) Etki ve duygular önceliklidir	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N
S1_MB_FC8	S1_self	MBTI	TF	A) Doğrudan geri bildirim veririm  |  B) İncitmemek için dili yumuşatırım	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N
S1_MB_FC9	S1_self	MBTI	TF	A) Adalet ve ilke  |  B) İlişki ve uyum önce gelir	ForcedChoice2	A|B	0	{"A":"TF:T","B":"TF:F"}	1	\N	\N
S1_MB_FC10	S1_self	MBTI	JP	A) Plan ve takvim isterim  |  B) Esnek kalmayı severim	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N
S1_MB_FC11	S1_self	MBTI	JP	A) Kararı hızlıca kapatırım  |  B) Seçenekleri bir süre açık tutarım	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N
S1_MB_FC12	S1_self	MBTI	JP	A) Belirsizlik rahatsız eder  |  B) Akışına bırakabilirim	ForcedChoice2	A|B	0	{"A":"JP:J","B":"JP:P"}	1	\N	\N
S1_AT_ANX1	S1_self	Attachment	ANX	Partnerim geç yanıt verdiğinde huzursuz olurum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ECR-R esinli	\N
S1_AT_ANX2	S1_self	Attachment	ANX	İlişkide sık sık güvence ihtiyacı hissederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX3	S1_self	Attachment	ANX	Terk edilme korkusu zaman zaman aklıma gelir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX4	S1_self	Attachment	ANX	Partnerimin sevgisini kanıtlamasına sık ihtiyaç duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX5	S1_self	Attachment	ANX	İlişkiyle ilgili olumsuz senaryoları zihnimde canlandırırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_ANX6	S1_self	Attachment	ANX	Partnerimle aram bozulduğunda hızla paniğe kapılırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO1	S1_self	Attachment	AVO	Duygularımı paylaşmakta zorlanırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO2	S1_self	Attachment	AVO	Yakınlık arttığında bir miktar geri çekilme ihtiyacı duyarım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO3	S1_self	Attachment	AVO	Bağımsızlık alanım kısıtlanınca huzursuz olurum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO4	S1_self	Attachment	AVO	Partnerimin duygusal ihtiyaçlarını karşılamak yorucu gelebilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO5	S1_self	Attachment	AVO	Problem olduğunda konuyu ertelemeyi tercih ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_AT_AVO6	S1_self	Attachment	AVO	Kişisel alanımın korunması benim için çok önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_ERQ_REAPP1	S1_self	EmotionReg	REAPP	Olumsuz bir olayı kafamda yeniden çerçevelemeye çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ERQ (yeniden değerlendirme) esinli	\N
S1_TKI_1	S1_self	Conflict	COMPETE	Evde ortak alanın dağınıklığı konusunda anlaşmazlık var; ilk eğiliminiz?	MultiChoice5	Bugünden itibaren net kurallar koyarım; uymayana açıkça uyarı yaparım.|Beraber kısa bir toplantı yapıp kural + görev paylaşımı oluşturmayı öneririm.|"Bu hafta ben, gelecek hafta siz" gibi orta yol teklif ederim.|Şimdilik açmam; uygun bir zamanda sakinleşince konuşmak isterim.|Sorun etmeyip ben toparlarım; siz nasıl rahatsanız öyle olsun.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	Günlük yaşam SJT	\N
S1_TKI_4	S1_self	Conflict	AVOID	Kalabalıkta biri sıranızı kesti; tepkiniz?	MultiChoice5	Netçe uyarır, yerime dönmesini isterim.|Çevreyle birlikte sırayı düzenleyelim, kibarca kuralı hatırlatırım.|Aceleyse bu kez geçmesine izin verelim; sırayı birlikte netleştirelim.|Tartışmaya girmem; görmezden gelirim.|Rahatsız olsam da sıramı veririm, mesele büyümesin.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N
S1_TKI_5	S1_self	Conflict	ACCOM	Yakınınız bir konuda duygusal olarak çok yoğun; yaklaşımınız?	MultiChoice5	Konuyu çözüme bağlamak için yönlendirir, somut adımlar belirlerim.|Hisleri ve ihtiyaçları birlikte konuşur, ortak plan çıkarırız.|Biraz konuşup orta noktada buluşalım, sonra kapatalım derim.|Şu an uygun değil; sakinleşince konuşalım derim.|Ne istiyorsa öyle yaparım; ona uyarım.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N
S1_TKI_7	S1_self	Conflict	COMPETE	Bir konuda doğru olduğunuzdan eminsiniz ve kanıt elinizde; stratejiniz?	MultiChoice5	Kanıtları sunar, kararı netleştiririm.|Kanıtları paylaşıp birlikte değerlendirir, ortak karar alırız.|Zaman kaybetmemek için kısmi uzlaşma öneririm.|Tartışmayı uzatmam; konuyu büyütmeden geçerim.|Karşı tarafı kırmamak için kendi görüşümden vazgeçerim.	0	{"Rekabet":"COMPETE","İşbirliği":"COLLAB","Uzlaşma":"COMPROM","Kaçınma":"AVOID","Uyum":"ACCOM"}	1	\N	\N
S1_ERQ_REAPP2	S1_self	EmotionReg	REAPP	Zor bir durumda durumu farklı bakış açılarından görmeye çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_ERQ_SUPPR1	S1_self	EmotionReg	SUPPR	Duygularımı dışa yansıtmamayı tercih ederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	ERQ (bastırma) esinli	\N
S1_ERQ_SUPPR2	S1_self	EmotionReg	SUPPR	Üzgün olsam bile yüzüme yansıtmam.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_ERQ_SUPPR3	S1_self	EmotionReg	SUPPR	Toplum içinde duygusal tepkilerimi bastırırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_EMP_PT1	S1_self	Empathy	PT	Birinin bakış açısını anlamak için aktif çaba gösteririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	IRI esinli	\N
S1_EMP_PT2	S1_self	Empathy	PT	Tartışmada karşı tarafın gerekçelerini anlamaya çalışırım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_EMP_EC1	S1_self	Empathy	EC	Başkalarının acısı beni duygusal olarak etkiler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_EMP_EC2	S1_self	Empathy	EC	Zor durumda olanlara karşı şefkat hissederim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_OE_STRENGTHS	S1_self	OpenEnded	OE	Kendinizde en güçlü bulduğunuz 3 özelliği yazınız.	OpenText		0	\N	1	\N	\N
S1_OE_WEAK	S1_self	OpenEnded	OE	Geliştirmek istediğiniz 3 alanı yazınız.	OpenText		0	\N	1	\N	\N
S1_OE_HAPPY	S1_self	LifeStory	OpenEnded	En mutlu anılarınızdan 1–3 tanesini yazınız (her biri ayrı paragraf).	OpenText		0	\N	1	Opsiyonel	\N
S1_OE_HARD	S1_self	LifeStory	OpenEnded	En zor/kötü anılarınızdan 1–3 tanesini yazınız (her biri ayrı paragraf).	OpenText		0	\N	1	Opsiyonel; travmatik detay şart değil	\N
S1_Q_CONS	S1_self	Quality	CONS	Bu testte dürüst cevap verdiğime inanıyorum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S1_Q_SPEED	S1_self	Quality	SPEED	Soruları acele etmeden yanıtladım.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	RT kalite ile birlikte kullanın	\N
S1_Q_REPEAT	S1_self	Quality	REPEAT	Benzer sorulara farklı cevap verdiğimi düşünüyorum.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	Tutarlılık	\N
S1_Q_ATTN	S1_self	Quality	IMC	Dikkat kontrolü: Lütfen bu madde için 'Katılıyorum' yani 4 nolu seçeneğini işaretleyiniz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	{"target":"Katılıyorum"}	1	Instructional Manipulation Check	\N
S2R_mother_E1	S2R_mother	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_A1	S2R_mother	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_C1	S2R_mother	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_N1	S2R_mother	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_O1	S2R_mother	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_E2	S2R_mother	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_EI1	S2R_mother	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_EI2	S2R_mother	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_SN1	S2R_mother	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_SN2	S2R_mother	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_TF1	S2R_mother	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_TF2	S2R_mother	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_JP1	S2R_mother	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_JP2	S2R_mother	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mother_COM1	S2R_mother	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_COL1	S2R_mother	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CRM1	S2R_mother	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_AVD1	S2R_mother	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_ACM1	S2R_mother	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_COL2	S2R_mother	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE1	S2R_mother	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE2	S2R_mother	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE3	S2R_mother	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_CLOSE4	S2R_mother	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL1	S2R_mother	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL2	S2R_mother	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL3	S2R_mother	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VAL4	S2R_mother	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VIG1	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mother_VIG2	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mother_VIG3	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VAL3	S2R_sibling	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_VIG4	S2R_mother	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mother_CONF1	S2R_mother	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mother_FREQ1	S2R_mother	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_father_E1	S2R_father	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_A1	S2R_father	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_C1	S2R_father	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_N1	S2R_father	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_O1	S2R_father	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_E2	S2R_father	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_EI1	S2R_father	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_EI2	S2R_father	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_SN1	S2R_father	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_SN2	S2R_father	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_TF1	S2R_father	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_TF2	S2R_father	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_JP1	S2R_father	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_JP2	S2R_father	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_father_COM1	S2R_father	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_COL1	S2R_father	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CRM1	S2R_father	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_AVD1	S2R_father	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_ACM1	S2R_father	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_COL2	S2R_father	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE1	S2R_father	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE2	S2R_father	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE3	S2R_father	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_CLOSE4	S2R_father	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL1	S2R_father	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL2	S2R_father	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL3	S2R_father	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VAL4	S2R_father	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_VIG1	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_VIG2	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_VIG3	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_VIG4	S2R_father	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_father_CONF1	S2R_father	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_father_FREQ1	S2R_father	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_sibling_E1	S2R_sibling	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_A1	S2R_sibling	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_C1	S2R_sibling	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_N1	S2R_sibling	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_O1	S2R_sibling	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_E2	S2R_sibling	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_EI1	S2R_sibling	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_EI2	S2R_sibling	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_SN1	S2R_sibling	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_SN2	S2R_sibling	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_TF1	S2R_sibling	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_TF2	S2R_sibling	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_JP1	S2R_sibling	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_JP2	S2R_sibling	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_sibling_COM1	S2R_sibling	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_COL1	S2R_sibling	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CRM1	S2R_sibling	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_AVD1	S2R_sibling	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_ACM1	S2R_sibling	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_COL2	S2R_sibling	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE1	S2R_sibling	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE2	S2R_sibling	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE3	S2R_sibling	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_CLOSE4	S2R_sibling	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VAL1	S2R_sibling	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VAL2	S2R_sibling	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VAL4	S2R_sibling	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_VIG1	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VIG2	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VIG3	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_VIG4	S2R_sibling	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_sibling_CONF1	S2R_sibling	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_sibling_FREQ1	S2R_sibling	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_relative_E1	S2R_relative	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_A1	S2R_relative	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_C1	S2R_relative	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_N1	S2R_relative	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_O1	S2R_relative	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_E2	S2R_relative	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_EI1	S2R_relative	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_EI2	S2R_relative	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_SN1	S2R_relative	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_SN2	S2R_relative	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_TF1	S2R_relative	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_TF2	S2R_relative	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_JP1	S2R_relative	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_JP2	S2R_relative	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_relative_COM1	S2R_relative	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_COL1	S2R_relative	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CRM1	S2R_relative	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_AVD1	S2R_relative	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_ACM1	S2R_relative	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_COL2	S2R_relative	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE1	S2R_relative	Closeness	BOUND	[AD] sınırlar zorlandığında sakin diyalog kurar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE2	S2R_relative	Closeness	CARE	[AD] eleştiride kırıcı olmamaya dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE3	S2R_relative	Closeness	INDEP	[AD] bağımsızlık ihtiyacına saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_CLOSE4	S2R_relative	Closeness	SUPPORT	[AD] kriz anında ulaşılabilirdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL1	S2R_relative	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL2	S2R_relative	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL3	S2R_relative	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VAL4	S2R_relative	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_VIG1	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_VIG2	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_VIG3	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_VIG4	S2R_relative	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_relative_CONF1	S2R_relative	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_relative_FREQ1	S2R_relative	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_best_friend_E1	S2R_best_friend	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_A1	S2R_best_friend	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_C1	S2R_best_friend	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_N1	S2R_best_friend	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_O1	S2R_best_friend	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_E2	S2R_best_friend	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_EI1	S2R_best_friend	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_EI2	S2R_best_friend	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_SN1	S2R_best_friend	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_SN2	S2R_best_friend	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_TF1	S2R_best_friend	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_TF2	S2R_best_friend	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_JP1	S2R_best_friend	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_JP2	S2R_best_friend	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_best_friend_COM1	S2R_best_friend	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_COL1	S2R_best_friend	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_CRM1	S2R_best_friend	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVD1	S2R_best_friend	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_ACM1	S2R_best_friend	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_COL2	S2R_best_friend	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL1	S2R_best_friend	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL2	S2R_best_friend	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL3	S2R_best_friend	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_AVAIL4	S2R_best_friend	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL1	S2R_best_friend	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL2	S2R_best_friend	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL3	S2R_best_friend	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VAL4	S2R_best_friend	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_VIG1	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_VIG2	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_VIG3	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_VIG4	S2R_best_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_best_friend_CONF1	S2R_best_friend	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_best_friend_FREQ1	S2R_best_friend	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_friend_E1	S2R_friend	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_A1	S2R_friend	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_C1	S2R_friend	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_N1	S2R_friend	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_O1	S2R_friend	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_E2	S2R_friend	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_EI1	S2R_friend	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_EI2	S2R_friend	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_SN1	S2R_friend	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_SN2	S2R_friend	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_TF1	S2R_friend	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_TF2	S2R_friend	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_JP1	S2R_friend	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_JP2	S2R_friend	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_friend_COM1	S2R_friend	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_COL1	S2R_friend	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_CRM1	S2R_friend	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVD1	S2R_friend	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_ACM1	S2R_friend	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_COL2	S2R_friend	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL1	S2R_friend	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL2	S2R_friend	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL3	S2R_friend	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_AVAIL4	S2R_friend	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL1	S2R_friend	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL2	S2R_friend	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL3	S2R_friend	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VAL4	S2R_friend	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_VIG1	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_VIG2	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_VIG3	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_VIG4	S2R_friend	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_friend_CONF1	S2R_friend	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_friend_FREQ1	S2R_friend	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_roommate_E1	S2R_roommate	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_A1	S2R_roommate	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_C1	S2R_roommate	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_N1	S2R_roommate	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_O1	S2R_roommate	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_E2	S2R_roommate	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_EI1	S2R_roommate	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_EI2	S2R_roommate	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_SN1	S2R_roommate	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_SN2	S2R_roommate	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_TF1	S2R_roommate	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_TF2	S2R_roommate	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_JP1	S2R_roommate	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_JP2	S2R_roommate	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_roommate_COM1	S2R_roommate	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_COL1	S2R_roommate	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_CRM1	S2R_roommate	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVD1	S2R_roommate	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_ACM1	S2R_roommate	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_COL2	S2R_roommate	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL1	S2R_roommate	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL2	S2R_roommate	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL3	S2R_roommate	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_AVAIL4	S2R_roommate	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL1	S2R_roommate	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL2	S2R_roommate	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL3	S2R_roommate	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VAL4	S2R_roommate	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_VIG1	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_VIG2	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_VIG3	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_VIG4	S2R_roommate	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_roommate_CONF1	S2R_roommate	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_roommate_FREQ1	S2R_roommate	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_neighbor_E1	S2R_neighbor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_A1	S2R_neighbor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_C1	S2R_neighbor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_N1	S2R_neighbor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_O1	S2R_neighbor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_E2	S2R_neighbor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_EI1	S2R_neighbor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_EI2	S2R_neighbor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_SN1	S2R_neighbor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_SN2	S2R_neighbor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_TF1	S2R_neighbor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_TF2	S2R_neighbor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_JP1	S2R_neighbor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_JP2	S2R_neighbor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_neighbor_COM1	S2R_neighbor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_COL1	S2R_neighbor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_CRM1	S2R_neighbor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVD1	S2R_neighbor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_ACM1	S2R_neighbor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_COL2	S2R_neighbor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL1	S2R_neighbor	Avail	TIME	[AD] düzenli görüşmeye/iletişime açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL2	S2R_neighbor	Avail	TRUST	[AD] sır saklar ve güven verir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL3	S2R_neighbor	Avail	CONFLICT	[AD] tartışma çıkınca kaçmadan konuşur.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_AVAIL4	S2R_neighbor	Avail	BAL	[AD] karşılıklılık dengesine dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL1	S2R_neighbor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL2	S2R_neighbor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL3	S2R_neighbor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VAL4	S2R_neighbor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_VIG1	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_VIG2	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_VIG3	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_VIG4	S2R_neighbor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_neighbor_CONF1	S2R_neighbor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_neighbor_FREQ1	S2R_neighbor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_crush_E1	S2R_crush	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_A1	S2R_crush	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_C1	S2R_crush	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_N1	S2R_crush	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_O1	S2R_crush	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_E2	S2R_crush	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_EI1	S2R_crush	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_EI2	S2R_crush	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_SN1	S2R_crush	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_SN2	S2R_crush	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_TF1	S2R_crush	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_TF2	S2R_crush	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_JP1	S2R_crush	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_JP2	S2R_crush	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_crush_COM1	S2R_crush	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_COL1	S2R_crush	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_CRM1	S2R_crush	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_AVD1	S2R_crush	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_ACM1	S2R_crush	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_COL2	S2R_crush	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_ANX1	S2R_crush	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_ANX2	S2R_crush	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_AVO1	S2R_crush	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_AVO2	S2R_crush	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL1	S2R_crush	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL2	S2R_crush	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL3	S2R_crush	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VAL4	S2R_crush	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_VIG1	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_VIG2	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_VIG3	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_VIG4	S2R_crush	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_crush_CONF1	S2R_crush	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_crush_FREQ1	S2R_crush	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_date_E1	S2R_date	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_A1	S2R_date	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_C1	S2R_date	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_N1	S2R_date	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_O1	S2R_date	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_E2	S2R_date	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_EI1	S2R_date	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_EI2	S2R_date	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_SN1	S2R_date	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_SN2	S2R_date	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_TF1	S2R_date	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_TF2	S2R_date	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_JP1	S2R_date	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_JP2	S2R_date	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_date_COM1	S2R_date	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_COL1	S2R_date	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_CRM1	S2R_date	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_AVD1	S2R_date	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_ACM1	S2R_date	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_COL2	S2R_date	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_ANX1	S2R_date	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_ANX2	S2R_date	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_AVO1	S2R_date	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_AVO2	S2R_date	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL1	S2R_date	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL2	S2R_date	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL3	S2R_date	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VAL4	S2R_date	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO1	S2R_mentee	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_VIG1	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_VIG2	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_VIG3	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_VIG4	S2R_date	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_date_CONF1	S2R_date	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_date_FREQ1	S2R_date	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_partner_E1	S2R_partner	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_A1	S2R_partner	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_C1	S2R_partner	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_N1	S2R_partner	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_O1	S2R_partner	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_E2	S2R_partner	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_EI1	S2R_partner	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_EI2	S2R_partner	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_SN1	S2R_partner	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_SN2	S2R_partner	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_TF1	S2R_partner	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_TF2	S2R_partner	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_JP1	S2R_partner	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_JP2	S2R_partner	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_partner_COM1	S2R_partner	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_COL1	S2R_partner	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_CRM1	S2R_partner	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_AVD1	S2R_partner	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_ACM1	S2R_partner	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_COL2	S2R_partner	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_ANX1	S2R_partner	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_ANX2	S2R_partner	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_AVO1	S2R_partner	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_AVO2	S2R_partner	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL1	S2R_partner	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL2	S2R_partner	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL3	S2R_partner	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VAL4	S2R_partner	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_VIG1	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_VIG2	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_VIG3	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_VIG4	S2R_partner	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_partner_CONF1	S2R_partner	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_partner_FREQ1	S2R_partner	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_fiance_E1	S2R_fiance	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_A1	S2R_fiance	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_C1	S2R_fiance	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_N1	S2R_fiance	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_O1	S2R_fiance	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_E2	S2R_fiance	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_EI1	S2R_fiance	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_EI2	S2R_fiance	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_SN1	S2R_fiance	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_SN2	S2R_fiance	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_TF1	S2R_fiance	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_TF2	S2R_fiance	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_JP1	S2R_fiance	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_JP2	S2R_fiance	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_fiance_COM1	S2R_fiance	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_COL1	S2R_fiance	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_CRM1	S2R_fiance	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_AVD1	S2R_fiance	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_ACM1	S2R_fiance	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_COL2	S2R_fiance	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_ANX1	S2R_fiance	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_ANX2	S2R_fiance	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_AVO1	S2R_fiance	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_AVO2	S2R_fiance	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL1	S2R_fiance	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL2	S2R_fiance	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL3	S2R_fiance	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VAL4	S2R_fiance	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_VIG1	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_VIG2	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_VIG3	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_VIG4	S2R_fiance	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_fiance_CONF1	S2R_fiance	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_fiance_FREQ1	S2R_fiance	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_spouse_E1	S2R_spouse	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_A1	S2R_spouse	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_C1	S2R_spouse	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_N1	S2R_spouse	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_O1	S2R_spouse	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_E2	S2R_spouse	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_EI1	S2R_spouse	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_EI2	S2R_spouse	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_SN1	S2R_spouse	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_SN2	S2R_spouse	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_TF1	S2R_spouse	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_TF2	S2R_spouse	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_JP1	S2R_spouse	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_JP2	S2R_spouse	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_spouse_COM1	S2R_spouse	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_COL1	S2R_spouse	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_CRM1	S2R_spouse	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_AVD1	S2R_spouse	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_ACM1	S2R_spouse	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_COL2	S2R_spouse	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_ANX1	S2R_spouse	Attachment	ANX	[AD] mesajlara geç dönüldüğünde huzursuz görünür.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_ANX2	S2R_spouse	Attachment	ANX	[AD] ilişkide güvence arar; sık teyit ister.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_AVO1	S2R_spouse	Attachment	AVO	[AD] duygularını paylaşmaktan kaçınır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_AVO2	S2R_spouse	Attachment	AVO	[AD] yakınlıktan sonra bir süre geri çekilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL1	S2R_spouse	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL2	S2R_spouse	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL3	S2R_spouse	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VAL4	S2R_spouse	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_VIG1	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_VIG2	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_VIG3	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_VIG4	S2R_spouse	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_spouse_CONF1	S2R_spouse	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_spouse_FREQ1	S2R_spouse	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_coworker_E1	S2R_coworker	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_A1	S2R_coworker	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_C1	S2R_coworker	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_N1	S2R_coworker	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_O1	S2R_coworker	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_E2	S2R_coworker	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_EI1	S2R_coworker	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_EI2	S2R_coworker	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_SN1	S2R_coworker	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_SN2	S2R_coworker	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_TF1	S2R_coworker	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_TF2	S2R_coworker	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_JP1	S2R_coworker	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_JP2	S2R_coworker	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_coworker_COM1	S2R_coworker	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_COL1	S2R_coworker	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_CRM1	S2R_coworker	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_AVD1	S2R_coworker	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_ACM1	S2R_coworker	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_COL2	S2R_coworker	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO1	S2R_coworker	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO2	S2R_coworker	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO3	S2R_coworker	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_PRO4	S2R_coworker	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL1	S2R_coworker	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL2	S2R_coworker	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL3	S2R_coworker	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VAL4	S2R_coworker	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_VIG1	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_VIG2	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_VIG3	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_VIG4	S2R_coworker	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_coworker_CONF1	S2R_coworker	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_coworker_FREQ1	S2R_coworker	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_manager_E1	S2R_manager	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_A1	S2R_manager	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_C1	S2R_manager	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_N1	S2R_manager	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_O1	S2R_manager	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_E2	S2R_manager	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_EI1	S2R_manager	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_EI2	S2R_manager	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_SN1	S2R_manager	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_SN2	S2R_manager	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_TF1	S2R_manager	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_TF2	S2R_manager	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_JP1	S2R_manager	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_JP2	S2R_manager	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_manager_COM1	S2R_manager	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_COL1	S2R_manager	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_CRM1	S2R_manager	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_AVD1	S2R_manager	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_ACM1	S2R_manager	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_COL2	S2R_manager	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO1	S2R_manager	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO2	S2R_manager	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO3	S2R_manager	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_PRO4	S2R_manager	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL1	S2R_manager	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL2	S2R_manager	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL3	S2R_manager	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VAL4	S2R_manager	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_VIG1	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_VIG2	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_VIG3	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_VIG4	S2R_manager	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_manager_CONF1	S2R_manager	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_manager_FREQ1	S2R_manager	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_direct_report_E1	S2R_direct_report	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_A1	S2R_direct_report	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_C1	S2R_direct_report	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_N1	S2R_direct_report	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_O1	S2R_direct_report	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_E2	S2R_direct_report	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_EI1	S2R_direct_report	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_EI2	S2R_direct_report	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_SN1	S2R_direct_report	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_SN2	S2R_direct_report	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_TF1	S2R_direct_report	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_TF2	S2R_direct_report	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_JP1	S2R_direct_report	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_JP2	S2R_direct_report	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_direct_report_COM1	S2R_direct_report	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_COL1	S2R_direct_report	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_CRM1	S2R_direct_report	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_AVD1	S2R_direct_report	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_ACM1	S2R_direct_report	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_COL2	S2R_direct_report	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO1	S2R_direct_report	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO2	S2R_direct_report	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO3	S2R_direct_report	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_PRO4	S2R_direct_report	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL1	S2R_direct_report	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL2	S2R_direct_report	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL3	S2R_direct_report	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VAL4	S2R_direct_report	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_VIG1	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_direct_report_VIG2	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_direct_report_VIG3	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_direct_report_VIG4	S2R_direct_report	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S0_CHRONOTYPE	S0_profile	Relationship	Chronotype	Kronotip (Gün içinde en verimli olduğunuz zaman dilimi):	SingleChoice	Sabah|Akşam|Karışık	0	\N	1	\N	13
S2R_direct_report_CONF1	S2R_direct_report	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_direct_report_FREQ1	S2R_direct_report	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_client_E1	S2R_client	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_A1	S2R_client	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_C1	S2R_client	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_N1	S2R_client	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_O1	S2R_client	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_E2	S2R_client	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_EI1	S2R_client	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_EI2	S2R_client	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_SN1	S2R_client	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_SN2	S2R_client	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_TF1	S2R_client	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_TF2	S2R_client	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_JP1	S2R_client	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_JP2	S2R_client	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_client_COM1	S2R_client	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_COL1	S2R_client	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_CRM1	S2R_client	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_AVD1	S2R_client	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_ACM1	S2R_client	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_COL2	S2R_client	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO1	S2R_client	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO2	S2R_client	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO3	S2R_client	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_PRO4	S2R_client	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL1	S2R_client	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL2	S2R_client	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL3	S2R_client	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VAL4	S2R_client	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_VIG1	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_VIG2	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_VIG3	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_VIG4	S2R_client	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_client_CONF1	S2R_client	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_client_FREQ1	S2R_client	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_vendor_E1	S2R_vendor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_A1	S2R_vendor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_C1	S2R_vendor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_N1	S2R_vendor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_O1	S2R_vendor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_E2	S2R_vendor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_EI1	S2R_vendor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_EI2	S2R_vendor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_SN1	S2R_vendor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_SN2	S2R_vendor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_TF1	S2R_vendor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_TF2	S2R_vendor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_JP1	S2R_vendor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_JP2	S2R_vendor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_vendor_COM1	S2R_vendor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_COL1	S2R_vendor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_CRM1	S2R_vendor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_AVD1	S2R_vendor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_ACM1	S2R_vendor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_COL2	S2R_vendor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO1	S2R_vendor	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO2	S2R_vendor	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO3	S2R_vendor	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_PRO4	S2R_vendor	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL1	S2R_vendor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL2	S2R_vendor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL3	S2R_vendor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_VAL4	S2R_vendor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S0_TIME_BUDGET_HRS	S0_profile	Relationship	TimeBudget	İlişkilere ayırabildiğiniz zaman (haftalık saat):	Number		0	\N	1	\N	14
S2R_vendor_VIG1	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_VIG2	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_VIG3	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_VIG4	S2R_vendor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_vendor_CONF1	S2R_vendor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_vendor_FREQ1	S2R_vendor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_mentor_E1	S2R_mentor	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_A1	S2R_mentor	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_C1	S2R_mentor	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_N1	S2R_mentor	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_O1	S2R_mentor	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_E2	S2R_mentor	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_EI1	S2R_mentor	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_EI2	S2R_mentor	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_SN1	S2R_mentor	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_SN2	S2R_mentor	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_TF1	S2R_mentor	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_TF2	S2R_mentor	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_JP1	S2R_mentor	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_JP2	S2R_mentor	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentor_COM1	S2R_mentor	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_COL1	S2R_mentor	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_CRM1	S2R_mentor	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_AVD1	S2R_mentor	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_ACM1	S2R_mentor	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_COL2	S2R_mentor	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO1	S2R_mentor	Pro	BOUND	[AD] profesyonel sınırlara dikkat eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO2	S2R_mentor	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO3	S2R_mentor	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_PRO4	S2R_mentor	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL1	S2R_mentor	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL2	S2R_mentor	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL3	S2R_mentor	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VAL4	S2R_mentor	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_VIG1	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_VIG2	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_VIG3	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_VIG4	S2R_mentor	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentor_CONF1	S2R_mentor	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentor_FREQ1	S2R_mentor	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S2R_mentee_E1	S2R_mentee	BigFive	E	[AD] sosyal ortamlarda sohbeti başlatır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_A1	S2R_mentee	BigFive	A	[AD] anlaşmazlıkta önce karşı tarafı anlamaya çalışır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_C1	S2R_mentee	BigFive	C	[AD] verdiği sözleri zamanında tutar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_N1	S2R_mentee	BigFive	N	[AD] stresli durumlarda kolayca gerilir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_O1	S2R_mentee	BigFive	O	[AD] yeni fikir ve deneyimlere açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_E2	S2R_mentee	BigFive	E	[AD] kalabalıkta geri planda kalmayı seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_EI1	S2R_mentee	MBTI	EI	[AD] uzun günün sonunda insanlarla vakit geçirerek toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_EI2	S2R_mentee	MBTI	EI	[AD] yalnız kalarak daha iyi toparlar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_SN1	S2R_mentee	MBTI	SN	[AD] somut veriler ve kanıtlarla konuşmayı tercih eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_SN2	S2R_mentee	MBTI	SN	[AD] olasılıklar/gelecek senaryolarını tartışmayı sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_TF1	S2R_mentee	MBTI	TF	[AD] karar verirken duygusal etkileri önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_TF2	S2R_mentee	MBTI	TF	[AD] karar verirken mantık ve tutarlılığı önceler.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_JP1	S2R_mentee	MBTI	JP	[AD] planlı ve takvimli ilerlemekten hoşlanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_JP2	S2R_mentee	MBTI	JP	[AD] seçenekleri açık tutmayı ve esnekliği sever.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	1	\N	1	\N	\N
S2R_mentee_COM1	S2R_mentee	Conflict	COMPETE	[AD] anlaşmazlıkta iddialı tavır alır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_COL1	S2R_mentee	Conflict	COLLAB	[AD] iki taraf için de uygun çözüm arar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_CRM1	S2R_mentee	Conflict	COMPROM	[AD] hızlı çözüm için orta yol önerir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_AVD1	S2R_mentee	Conflict	AVOID	[AD] gerilim çıktığında konuyu ertelemeyi seçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_ACM1	S2R_mentee	Conflict	ACCOM	[AD] karşı tarafı kırmamak için kendi isteğinden vazgeçer.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_COL2	S2R_mentee	Conflict	COLLAB	[AD] ortak zemini bulmak için aktif soru sorar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO2	S2R_mentee	Pro	FEED	[AD] anlaşmazlıkta profesyonel kalır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO3	S2R_mentee	Pro	TRUST	[AD] gizliliğe riayet eder.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_PRO4	S2R_mentee	Pro	TIME	[AD] teslim tarihine saygı duyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL1	S2R_mentee	Values	BOUND	[AD] kişisel alan/mahremiyete saygı gösterir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL2	S2R_mentee	Values	SUPPORT	[AD] pratik/duygusal destek sunar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL3	S2R_mentee	Values	RESPECT	[AD] saygılı bir dil kullanır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VAL4	S2R_mentee	Values	ALIGN	[AD] birlikte belirlenen kurallara uyar.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_VIG1	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_VIG2	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_VIG3	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_VIG4	S2R_mentee	Vignette	Conflict	Durumsal çatışma senaryosu – [AD] nasıl tepki verir?	MultiChoice5	A: Sertçe karşı çıkarım (Rekabet)|B: Konuyu erteleyip sakinleşince konuşurum (Kaçınma)|C: Orta yolu teklif ederim (Uzlaşma)|D: Önce onun ihtiyacını öne alırım (Uyum)|E: İki tarafın da kazanacağı çözüm ararım (İşbirliği)	0	{"A": "COMPETE", "B": "AVOID", "C": "COMPROM", "D": "ACCOM", "E": "COLLAB"}	1	\N	\N
S2R_mentee_CONF1	S2R_mentee	Quality	CONF	[AD] hakkında verdiğim cevaplardan eminim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S2R_mentee_FREQ1	S2R_mentee	Quality	FREQ	[AD] ile etkileşim sıklığımız:	Likert5	Çok nadir|Ayda birkaç|Haftada 1–2|Haftada 3+|Hemen her gün	0	\N	1	\N	\N
S3_EI_1	S3_self	MBTI	EI	Yoğun bir günün sonunda enerjimi yenilemek için: A) insanlarla vakit geçiririm B) yalnız kalırım	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N
S3_EI_2	S3_self	MBTI	EI	Yeni bir ortama girdiğimde: A) hızlıca kaynaşırım B) önce gözlemler sonra dahil olurum	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N
S3_EI_3	S3_self	MBTI	EI	Beyin fırtınasında: A) yüksek sesle düşünürüm B) önce zihnimde netleştiririm	ForcedChoice2	A|B	0	{"A": "E", "B": "I"}	1	\N	\N
S3_SN_1	S3_self	MBTI	SN	Bir projeyi tartışırken önce: A) somut detay/kanıt B) büyük resim/olasılık	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N
S3_SN_2	S3_self	MBTI	SN	Bir konuyu anlamak için: A) mevcut gerçekler B) olası senaryolar	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N
S3_SN_3	S3_self	MBTI	SN	Yenilik karşısında: A) işe yararlık B) potansiyel fırsat	ForcedChoice2	A|B	0	{"A": "S", "B": "N"}	1	\N	\N
S3_TF_1	S3_self	MBTI	TF	Zor bir kararda: A) tutarlılık/adalet B) duygusal etki	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N
S3_TF_2	S3_self	MBTI	TF	Geri bildirim verirken: A) net/doğrudan B) hissi gözeterek	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N
S3_TF_3	S3_self	MBTI	TF	Çatışmada: A) problemi mantıkla çözerim B) duygusal etkiyi önce ele alırım	ForcedChoice2	A|B	0	{"A": "T", "B": "F"}	1	\N	\N
S3_JP_1	S3_self	MBTI	JP	Planlar: A) net takvim/kapalı uçlu B) seçenekler açık/akışkan	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N
S3_JP_2	S3_self	MBTI	JP	Son dakika değişimi: A) rahatsız eder B) esnek davranırım	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N
S3_JP_3	S3_self	MBTI	JP	Görev stili: A) bitişten önce tamamlarım B) son ana kadar seçenekler açık	ForcedChoice2	A|B	0	{"A": "J", "B": "P"}	1	\N	\N
S4_family_1	S4_family	ValuesBoundaries	BOUND	Aile içinde kişisel mahremiyete saygı önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_2	S4_family	ValuesBoundaries	COMM	Zor konuları sakin bir dille konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_3	S4_family	ValuesBoundaries	ROLE	Ev içi roller net olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_4	S4_family	ValuesBoundaries	SUPPORT	Duygusal destek göstermek değerlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_5	S4_family	ValuesBoundaries	BOUND	Özel eşyaları izinsiz kullanmak kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_6	S4_family	ValuesBoundaries	COMM	Eleştiride kırıcı olmamaya özen gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_7	S4_family	ValuesBoundaries	DECISION	Önemli kararlar ortak alınmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_8	S4_family	ValuesBoundaries	TIME	Aile zamanı için düzenli vakit ayırmak önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_9	S4_family	ValuesBoundaries	CONFLICT	Gerilimde kısa mola verip yeniden konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_10	S4_family	ValuesBoundaries	RESPECT	Kuşak farkı olsa da saygı korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_11	S4_family	ValuesBoundaries	FINANCE	Hane içi harcamalarda şeffaflık gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_12	S4_family	ValuesBoundaries	BOUND	Misafir/ziyaret planında önceden haber verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_13	S4_family	ValuesBoundaries	SUPPORT	Krizde ulaşılabilir olmak önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_14	S4_family	ValuesBoundaries	INDEP	Bağımsızlık alanına saygı duyulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_15	S4_family	ValuesBoundaries	DIGI	Dijital/telefon gizliliği gözetilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_16	S4_family	ValuesBoundaries	PRIV	Aile sırları üçüncü kişilerle paylaşılmamalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_17	S4_family	ValuesBoundaries	CARE	Hassas konular (sağlık vb.) özenle konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_18	S4_family	ValuesBoundaries	FAIR	Sorumluluklar adil paylaşılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_19	S4_family	ValuesBoundaries	BOUND	Ses yükseltmek sınır ihlalidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_family_20	S4_family	ValuesBoundaries	REPAIR	Kırgınlıkta özür ve onarım beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_1	S4_friend	ValuesBoundaries	BOUND	Plan değişikliğinde zamanında haber verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_2	S4_friend	ValuesBoundaries	TRUST	Sırlar gizli tutulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_3	S4_friend	ValuesBoundaries	TIME	Düzenli görüşmeye önem veririm.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_4	S4_friend	ValuesBoundaries	FUN	Ortak aktivite planlamayı severim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_5	S4_friend	ValuesBoundaries	RESPECT	İğneleyici şakalardan kaçınılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_6	S4_friend	ValuesBoundaries	SUPPORT	Zor günde mesaj/arayış beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_7	S4_friend	ValuesBoundaries	BOUND	Özel hayatımın sınırlarına saygı gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_8	S4_friend	ValuesBoundaries	COMM	Sorunları açık ve sakin konuşabilmeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_9	S4_friend	ValuesBoundaries	FAIR	Harcama paylaşımında adalet önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_10	S4_friend	ValuesBoundaries	DIGI	Ekran görüntülerimi izinsiz paylaşmak kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_11	S4_friend	ValuesBoundaries	RELIAB	Verilen sözlerin tutulması gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_12	S4_friend	ValuesBoundaries	CONFLICT	Tartışmayı kaçırmadan çözüme odaklanmalıyız.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_13	S4_friend	ValuesBoundaries	FEED	Geri bildirimi iyi niyetle vermeliyiz.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_14	S4_friend	ValuesBoundaries	PRIOR	Öncelikler çatıştığında açık iletişim beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_15	S4_friend	ValuesBoundaries	BOUND	Rızam olmadan eşyalarım kullanılmamalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_16	S4_friend	ValuesBoundaries	BAL	Karşılıklılık dengesi önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_17	S4_friend	ValuesBoundaries	REPAIR	Kırgınlık sonrası onarım beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_18	S4_friend	ValuesBoundaries	TIME	Son dakika iptalleri minimum olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_19	S4_friend	ValuesBoundaries	TRUST	Gıyabımda saygılı konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_friend_20	S4_friend	ValuesBoundaries	SUPPORT	Başarılarımı takdir etmesini beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_1	S4_work	ValuesBoundaries	PRO	Profesyonel sınırlara özen gösterilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_2	S4_work	ValuesBoundaries	COMM	Geri bildirim açık ve saygılı verilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_3	S4_work	ValuesBoundaries	OWN	Sorumluluk üstlenmek ve takip önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_4	S4_work	ValuesBoundaries	ALIGN	Ekip hedefleriyle hizalanma gereklidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_5	S4_work	ValuesBoundaries	TIME	Toplantı ve teslim tarihlerine uyum esastır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_6	S4_work	ValuesBoundaries	TRUST	Bilgi gizliliği korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_7	S4_work	ValuesBoundaries	BOUND	Mesai dışı yazışmalara makul sınır getirilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_8	S4_work	ValuesBoundaries	FAIR	İş yükü adil dağıtılmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_9	S4_work	ValuesBoundaries	CONFLICT	Uyuşmazlıklar kişiselleştirilmeden ele alınmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_10	S4_work	ValuesBoundaries	RESPECT	Hiyerarşi olsa da saygı korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_11	S4_work	ValuesBoundaries	FEED	Net hedef ve beklenti belirlenmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_12	S4_work	ValuesBoundaries	REPAIR	Hata sonrası onarım/öğrenme beklenir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_13	S4_work	ValuesBoundaries	OWN	Hatalarda sorumluluk almak değerlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_14	S4_work	ValuesBoundaries	BOUND	Kişisel konular iş ortamında sınırında kalmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_15	S4_work	ValuesBoundaries	ALIGN	Kararlar şeffaf iletişilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_16	S4_work	ValuesBoundaries	TRUST	Krediyi hakkaniyetle paylaşmak gerekir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_17	S4_work	ValuesBoundaries	TIME	Fazla mesai beklentisi şeffaf olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_18	S4_work	ValuesBoundaries	PRO	Toplantıda söz kesmemek önemlidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_19	S4_work	ValuesBoundaries	COMM	E-posta/mesaj tonuna dikkat edilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_work_20	S4_work	ValuesBoundaries	SAFETY	Psikolojik güvenlik korunmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_1	S4_romantic	ValuesBoundaries	BOUND	Özel alan ve kişisel zamana saygı beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_2	S4_romantic	ValuesBoundaries	FINANCE	Maddi konularda şeffaflık isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_3	S4_romantic	ValuesBoundaries	COMM	Duyguların düzenli ifade edilmesini isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_4	S4_romantic	ValuesBoundaries	DIGI	Sosyal medyada mahremiyete dikkat edilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_5	S4_romantic	ValuesBoundaries	LOYAL	Sadakat kırmızı çizgimdir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_6	S4_romantic	ValuesBoundaries	TRUST	Güven inşası için tutarlı davranış beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_7	S4_romantic	ValuesBoundaries	TIME	Kaliteli birlikte zaman önceliklidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_8	S4_romantic	ValuesBoundaries	SEX	Rıza ve sınırlar açık konuşulmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_9	S4_romantic	ValuesBoundaries	REPAIR	Kırgınlıkta özür ve telafi beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_10	S4_romantic	ValuesBoundaries	BOUND	Kıskançlık kontrolü ve iletişimle yönetilmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_11	S4_romantic	ValuesBoundaries	FAIR	Ev/ilişki sorumlulukları adil bölüşülmelidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_12	S4_romantic	ValuesBoundaries	FAM	Aile/arkadaş etkisi makul sınırda kalmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_13	S4_romantic	ValuesBoundaries	COMM	Tartışmada ses yükseltmek sınır ihlalidir.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_14	S4_romantic	ValuesBoundaries	PLAN	Gelecek planlarında fikirlerime değer verilmeli.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_15	S4_romantic	ValuesBoundaries	DIGI	Konum/mesaj denetimi talebi kabul edilemez.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_16	S4_romantic	ValuesBoundaries	SUPPORT	Zor günlerde yanında olmasını beklerim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_17	S4_romantic	ValuesBoundaries	FUN	Birlikte keyifli rutini sürdürmek isterim.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_18	S4_romantic	ValuesBoundaries	BOUND	Flört/iletişim sınırları net olmalıdır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_19	S4_romantic	ValuesBoundaries	TRUST	Şeffaflık ve dürüstlük esastır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S4_romantic_20	S4_romantic	ValuesBoundaries	REPAIR	İlişki sorunlarında profesyonel destek opsiyonu açıktır.	Likert5	Kesinlikle Katılmıyorum|Katılmıyorum|Kararsızım|Katılıyorum|Kesinlikle Katılıyorum	0	\N	1	\N	\N
S0_VALUES_TOP3	S0_profile	Values	Top3	Öncelikli değerlerim (en fazla 3 seçiniz):	MultiSelect	Dürüstlük|Sadakat|Özgürlük|Adalet|Başarı|Şefkat|Düzen|Yaratıcılık|Macera|Güvenlik|Saygı	0	\N	1	Maksimum 3 önerilir.	24
S0_MONEY_TALK_EASE	S0_profile	Values	MoneyTalk	Para/sorumluluk konuşma rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	25
S0_SOCIAL_VIS_EASE	S0_profile	Values	SocialVisibility	Sosyal medya görünürlüğü rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	26
S0_SUPPORT_SIZE	S0_profile	Support	Circle	Yakın destek halkası (kişi sayısı):	Number		0	\N	1	\N	27
S0_LOVE_LANG_ORDER	S0_profile	Romantic	LoveLangs	Sevgi dillerim (öncelik sırası—seçim sırasına göre):	RankedMulti	Onay sözleri|Kaliteli zaman|Hizmet|Hediye|Temas	0	\N	1	Sadece romantik bağlamda gösterin.	29
S0_TOUCH_COMFORT	S0_profile	Romantic	TouchComfort	Fiziksel temas rahatlığım:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	Sadece romantik bağlamda gösterin.	30
S0_CONSENT	S0_profile	Consent	Use	Analiz ve koçluk için verdiğim bilgilerin işlenmesini onaylıyorum.	SingleChoice	Evet|Hayır	0	\N	1	\N	31
S0_LIKES	S0_profile	Preferences	Likes	Sevdiğiniz şeyler (aktiviteler insanlar ortamlar):	OpenText		0	\N	1	Örn: Açık havada vakit geçirmek, derin sohbetler, yeni yerler keşfetmek...	16
S0_DISLIKES	S0_profile	Preferences	Dislikes	Sevmediğiniz / kaçındığınız şeyler:	OpenText		0	\N	1	Örn: Gürültülü ortamlar, geç kalınması, yalan söylenmesi...	17
S0_REL_GOALS	S0_profile	Goals	RelGoals	İlişkilerde kısa/orta vadeli hedefleriniz:	OpenText		0	\N	1	Örn: Daha iyi iletişim kurmak, güven inşa etmek, sınırları belirlemek...	19
S0_BOUNDARIES	S0_profile	Goals	Boundaries	Sınırlarınız / kırmızı çizgileriniz:	OpenText		0	\N	1	Örn: Yalan, aldatma, saygısızlık, şiddet...	20
S0_TOP_CHALLENGES	S0_profile	Challenges	TopChallenges	Sizi şu an en çok zorlayan konular:	OpenText		0	\N	1	Örn: İş yükü, aile ilişkileri, maddi konular, sağlık...	21
S0_NEAR_TERM	S0_profile	Challenges	NearTerm	Yakın zamanda çözmeniz gereken güçlük(ler):	OpenText		0	\N	1	Örn: Yeni iş bulma, taşınma, borç ödeme, sınav hazırlık...	22
S0_TRIGGERS	S0_profile	Challenges	Triggers	Bilinen çatışma tetikleyicilerim:	OpenText		0	\N	1	Örn: Alaycı üslup, eleştiri, plansızlık, ses tonu...	23
S0_COPING	S0_profile	Support	Coping	Sık kullandığım başa çıkma stratejileri:	OpenText		0	\N	1	Örn: Yürüyüş, meditasyon, müzik dinleme, arkadaşlarla konuşma...	28
S0_WHY_NEED	S0_profile	Consent	WhyNeed	Bu uygulamaya neden ihtiyaç duydunuz? (Anket amaçlı değil sizi tanımak ve ihtiyaçlarınızı anlamak için)	OpenText		0	\N	1	Örn: İlişkilerimi geliştirmek, kendimi tanımak, çatışmaları çözmek istiyorum...	32
S0_AGE	S0_profile	Demographics	Age	Yaşınız (sayı olarak):	Number		0	\N	1	\N	1
S0_GENDER	S0_profile	Demographics	Gender	Cinsiyetiniz (opsiyonel):	SingleChoice	Kadın|Erkek|Diğer|Belirtmek istemiyorum	0	\N	1	\N	2
S0_WORK_STATUS	S0_profile	EducationWork	WorkStatus	Şu an çalışma durumunuz:	SingleChoice	Çalışıyorum|Çalışmıyorum|İş arıyorum|Serbest	0	\N	1	\N	3
S0_STUDY_ACTIVE	S0_profile	EducationWork	StudyActive	Öğrenim durumunuz:	SingleChoice	Okuyorum|Okumuyorum	0	\N	1	\N	4
S0_SCHOOL_TYPE	S0_profile	EducationWork	SchoolType	Son/Güncel okul türü:	SingleChoice	Lise|Ön lisans|Lisans (Üniversite)|Yüksek Lisans|Doktora|Diğer	0	\N	1	Etiket: Okuyorum→Güncel okul; Okumuyorum→Son mezun olunan okul	5
S0_WORK_PACE	S0_profile	EducationWork	Pace	Çalışma/okul temposu:	SingleChoice	Düzenli mesai|Vardiya|Serbest|Yoğun dönemli	0	\N	1	\N	7
S0_STRESS_NOW	S0_profile	EducationWork	Stress	Güncel stres düzeyim:	Likert5	Çok Az|Az|Orta|Fazla|Çok Fazla	0	\N	1	\N	8
S0_COMMUTE_MIN	S0_profile	EducationWork	Commute	Günlük yol/lojistik yük (dakika):	Number		0	\N	1	Opsiyonel	9
S0_REL_STATUS	S0_profile	Relationship	Status	Medeni/İlişki durumunuz:	SingleChoice	Bekâr|İlişkim var|Nişanlı|Evli|Ayrı yaşıyorum|Boşanmış|Diğer	0	\N	1	\N	10
S0_LIVE_WITH	S0_profile	Relationship	Household	Birlikte yaşadıklarım:	MultiSelect	Yalnız|Ailemle|Ev arkadaşı|Partner|Çocuk(lar)|Bakımını üstlendiğim biri	0	\N	1	\N	11
S0_CARE_DUTIES	S0_profile	Relationship	Care	Bakım sorumluluğu:	MultiSelect	Çocuk|Yaşlı yakını|Engelli yakını|Evcil hayvan|Yok	0	\N	1	\N	12
S0_SCHOOL_FIELD	S0_profile	EducationWork	SchoolField	Bölüm/Alan:	OpenText		0	\N	1	Örn: Bilgisayar Mühendisliği, İşletme, Tıp, Hukuk...	6
S0_HOBBIES	S0_profile	Preferences	Hobbies	Hobileriniz / ilgi alanlarınız:	OpenText		0	\N	1	Örn: Kitap okuma, yüzme, müzik, doğa yürüyüşü, yemek yapma...	15
S0_LIFE_GOAL	S0_profile	Goals	LifePurpose	Hayattaki amacınız / yönünüz:	OpenText		0	\N	1	Örn: İnsanlara yardım etmek, sürekli öğrenmek, aileme iyi bir hayat sağlamak...	18
S1_DISC_SJT1	S1_self	DISC	DISC	Evde acil karar gerektiren bir durum var (örn. su sızıntısı); ilk tutumunuz?	MultiChoice4	Ana vanayı kapatır, ustayı arar, gerekirse komşuyu bilgilendiririm.|Mahalle/WhatsApp grubunda yardım çağırır, çevreyi hızla organize ederim.|Evdeki herkesin sakin olduğundan emin olur, görevleri paylaşarak destek olurum.|Kaynağı kontrol eder, foto/video ile durumu belgeleyip sigorta/yönetimle prosedürü başlatırım.	0	\N	1	\N	70
S1_DISC_SJT3	S1_self	DISC	DISC	Aldığınız üründe sorun çıktı; ilk odağınız?	MultiChoice4	Satıcıyla hemen iletişime geçip değişim/iade talep ederim.|Müşteri temsilcisiyle olumlu bir diyalog kurup çözümü hızlandırırım.|Yakın çevreme danışıp birlikte en pratik adımı atarım.|Fatura/garanti ve arıza notlarını toplayıp üretici kılavuzuna göre ilerlerim.	0	\N	1	\N	72
S1_DISC_SJT4	S1_self	DISC	DISC	Plan dışı değişiklik talebi geldi (örn. tatil rotası); refleksiniz?	MultiChoice4	Yeni rotayı hızla belirleyip programa geçiririm.|Değişikliğin cazibesini anlatarak grubu ikna ederim.|Herkesin rahat edeceği orta yolu bulmak için öneri toplarım.|Alternatifleri süre/maliyet/riske göre kısa karşılaştırır, veriye dayalı öneri getiririm.	0	\N	1	\N	73
S1_DISC_SJT6	S1_self	DISC	DISC	Yakın çevrede moral düşük (ör. arkadaş üzgün); ilk hamleniz?	MultiChoice4	Pratik çözüm seçenekleri çıkarır, küçük bir aksiyon planı yaparım.|Moral yükselten bir sohbet/aktivite organize ederim.|Yanında sakince bulunur, dinler ve duygusal destek veririm.|Durumu sistematik değerlendirir, uygun kaynak/uzman öneririm.	0	\N	1	\N	75
S1_DISC_SJT7	S1_self	DISC	DISC	Aynı zamana denk gelen aile ve arkadaş planları çakıştı; yaklaşımınız?	MultiChoice4	Önceliklendirme yapar, net bir karar verip birini iptal ederim.|Herkese yazıp esnek, yeni ortak bir zaman bulmaya çalışırım.|Kimseyi kırmamak için kısa süreli/ardışık katılım planlarım.|Takvim/lojistik analiz yapar, en verimli seçeneği seçerim.	0	\N	1	\N	76
S1_DISC_SJT9	S1_self	DISC	DISC	Komşudan gece geç saatte yüksek ses geliyor; ilk yaklaşımınız ne olur?	MultiChoice4	Kapısını çalar, netçe rahatsızlığı iletip sesin kısılmasını isterim.|Site/WhatsApp grubunda kibar bir mesajla konuyu anlatır, destek isterim.|Sabah uygun bir zamanda sakin bir dille konuşmayı teklif ederim.|Site kuralları/yönetmeliği kontrol edip uygun kanaldan resmi bildirim yaparım.	0	\N	1	\N	78
S1_DISC_SJT10	S1_self	DISC	DISC	Ortak kullanılan ev/mutfakta bulaşıklar birikiyor; nasıl ilerlersiniz?	MultiChoice5	Bundan sonra kuralları ben koyarım; herkes uysun.|Birlikte küçük bir plan yapalım (takvim, görev paylaşımı).|Herkes biraz taviz versin; bugün ben hallederim, yarın siz.|Şimdilik görmezden gelelim; uygun zamanda konuşuruz.|Ben hallederim; siz nasıl rahatsanız öyle olsun.	0	\N	1	\N	79
\.


--
-- Data for Name: language_incidents; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.language_incidents (id, user_id, report_type, user_language, detected_language, content_preview, created_at) FROM stdin;
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.messages (id, session_id, role, content, created_at) FROM stdin;
\.


--
-- Data for Name: people; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.people (id, user_id, label, relation_type, gender, age, notes) FROM stdin;
\.


--
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, owner_user_id, dyad_id, markdown, version) FROM stdin;
\.


--
-- Data for Name: responses; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.responses (id, assessment_id, item_id, value, rt_ms) FROM stdin;
\.


--
-- Data for Name: scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scores (id, assessment_id, bigfive_json, mbti_json, enneagram_json, attachment_json, conflict_json, social_json, quality_flags) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, locale, created_at) FROM stdin;
\.


--
-- Name: responses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.responses_id_seq', 1, false);


--
-- Name: assessments assessments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_pkey PRIMARY KEY (id);


--
-- Name: chat_sessions chat_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_sessions
    ADD CONSTRAINT chat_sessions_pkey PRIMARY KEY (id);


--
-- Name: dyad_scores dyad_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyad_scores
    ADD CONSTRAINT dyad_scores_pkey PRIMARY KEY (id);


--
-- Name: dyads dyads_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: language_incidents language_incidents_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language_incidents
    ADD CONSTRAINT language_incidents_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- Name: responses responses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_pkey PRIMARY KEY (id);


--
-- Name: scores scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_people_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_people_user ON public.people USING btree (user_id);


--
-- Name: idx_resp_assessment; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resp_assessment ON public.responses USING btree (assessment_id);


--
-- Name: idx_resp_item; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_resp_item ON public.responses USING btree (item_id);


--
-- Name: assessments assessments_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assessments
    ADD CONSTRAINT assessments_person_id_fkey FOREIGN KEY (person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: chat_sessions chat_sessions_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chat_sessions
    ADD CONSTRAINT chat_sessions_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: dyad_scores dyad_scores_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyad_scores
    ADD CONSTRAINT dyad_scores_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: dyads dyads_a_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_a_person_id_fkey FOREIGN KEY (a_person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: dyads dyads_b_person_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dyads
    ADD CONSTRAINT dyads_b_person_id_fkey FOREIGN KEY (b_person_id) REFERENCES public.people(id) ON DELETE CASCADE;


--
-- Name: language_incidents language_incidents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.language_incidents
    ADD CONSTRAINT language_incidents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: messages messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.chat_sessions(id) ON DELETE CASCADE;


--
-- Name: people people_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports reports_dyad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_dyad_id_fkey FOREIGN KEY (dyad_id) REFERENCES public.dyads(id) ON DELETE CASCADE;


--
-- Name: reports reports_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: responses responses_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: responses responses_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responses
    ADD CONSTRAINT responses_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;


--
-- Name: scores scores_assessment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scores
    ADD CONSTRAINT scores_assessment_id_fkey FOREIGN KEY (assessment_id) REFERENCES public.assessments(id) ON DELETE CASCADE;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

