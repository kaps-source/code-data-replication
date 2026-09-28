Se esperan 107 archivos .txt numerados 1.txt ... 107.txt en
seeds/raw/, junto a este script. Los archivos procesados se guardan en seeds/
con el sufijo _limpio.txt. Se crea all_text_analysis_top100.xlsx junto al
script, con dos hojas: unigramas y bigramas. Cada fila corresponde
a un artículo y cada columna de términos contiene su frecuencia en ese artículo.

Se pueden indicar otras rutas.
El Top-100 es un conjunto de candidatos ordenados por frecuencia global.

import argparse
from collections import Counter
import os
from pathlib import Path
import re
import tempfile

import nltk
import pandas as pd
from nltk.corpus import stopwords, words as nltk_words
from nltk.stem import WordNetLemmatizer
from nltk.tokenize import word_tokenize


TOP_N = 100
EXPECTED_DOCUMENTS = 107
ARCHIVED_TOKENS = 368_085
ARCHIVED_BIGRAMS = 367_978


def load_resource(name, getter):
    """Utiliza un corpus NLTK instalado o lo descarga una sola vez."""
    try:
        return getter()
    except LookupError:
        if not nltk.download(name, quiet=True):
            raise RuntimeError(
                f"Falta el recurso NLTK {name!r}. Instálelo con "
                f"'python -m nltk.downloader {name}' y vuelva a ejecutar."
            ) from None
        return getter()


def normalize(text):
    """Conserva exactamente el orden de limpieza del script archivado."""
    text = text.lower()
    text = re.sub(r"[^\w\s]", " ", text)
    text = re.sub(r"\d+", "", text)
    return re.sub(r"\s+", " ", text).strip()


def preprocess(text, stop_words, english_words, lemmatizer):
    # Tras la normalización el texto ocupa una sola línea. preserve_line=True
    # mantiene word_tokenize y evita necesitar el modelo de oraciones punkt.
    tokens = word_tokenize(normalize(text), preserve_line=True)
    tokens = [token for token in tokens if token not in stop_words]
    tokens = [lemmatizer.lemmatize(token) for token in tokens]
    return [
        token for token in tokens
        if len(token) > 3 or (len(token) > 1 and token in english_words)
    ]


def numbered_raw_files(raw_dir, expected_documents):
    if not raw_dir.is_dir():
        raise FileNotFoundError(f"No existe la carpeta de textos originales: {raw_dir}")

    paths = [p for p in raw_dir.iterdir() if p.is_file() and p.suffix.lower() == ".txt"]
    numbers = {}
    for path in paths:
        match = re.fullmatch(r"(\d+)(?:_.*)?", path.stem)
        if not match or path.stem.lower().endswith("_limpio"):
            raise ValueError(f"Nombre de texto original no válido: {path.name}")
        number = int(match.group(1))
        if number in numbers:
            raise ValueError(
                f"Hay dos textos con el número {number}: "
                f"{numbers[number].name} y {path.name}"
            )
        numbers[number] = path

    wanted = set(range(1, expected_documents + 1))
    if set(numbers) != wanted:
        missing = sorted(wanted - set(numbers))
        extra = sorted(set(numbers) - wanted)
        raise ValueError(
            f"Se esperan los documentos 1 a {expected_documents}. "
            f"Faltan: {missing}; sobran: {extra}."
        )
    return [numbers[number] for number in sorted(numbers)]


def write_text(path, content):
    """Evita dejar un TXT incompleto si se interrumpe una escritura."""
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=path.parent,
            prefix=f".{path.stem}_", suffix=".tmp", delete=False,
        ) as stream:
            temp_path = Path(stream.name)
            stream.write(content)
        os.replace(temp_path, path)
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)


def make_matrix(names, per_document_counts, top_terms, bigrams=False):
    """Frecuencias enteras por documento, con columnas en orden Top-100."""
    terms = [(" ".join(term) if bigrams else term) for term, _ in top_terms]
    columns = {"paper": names}
    for term, (key, _) in zip(terms, top_terms):
        columns[term] = [counts[key] for counts in per_document_counts]
    return pd.DataFrame(columns)


def write_workbook(path, unigrams, bigrams):
    """Guarda las dos matrices sin hojas intermedias ni una salida parcial."""
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=path.parent, prefix=".unigramas_bigramas_",
            suffix=".xlsx", delete=False,
        ) as stream:
            temp_path = Path(stream.name)
        with pd.ExcelWriter(temp_path, engine="xlsxwriter") as writer:
            unigrams.to_excel(writer, sheet_name="unigramas", index=False)
            bigrams.to_excel(writer, sheet_name="bigramas", index=False)
        os.replace(temp_path, path)
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)


def run(raw_dir, clean_dir, excel_output, expected_documents=EXPECTED_DOCUMENTS):
    if expected_documents < 1:
        raise ValueError("--expected-documents debe ser mayor que cero.")
    raw_dir = raw_dir.resolve()
    clean_dir = clean_dir.resolve()
    excel_output = excel_output.resolve()
    if raw_dir == clean_dir:
        raise ValueError("Las carpetas de textos originales y limpios deben ser distintas.")

    original_files = numbered_raw_files(raw_dir, expected_documents)
    lemmatizer = WordNetLemmatizer()
    stop_words = set(load_resource("stopwords", lambda: stopwords.words("english")))
    english_words = set(load_resource("words", lambda: nltk_words.words()))
    load_resource("wordnet", lambda: lemmatizer.lemmatize("seeds"))

    # 1. Limpieza de todos los originales; se excluyen deliberadamente los
    # *_limpio.txt de ejecuciones anteriores al construir las matrices.
    clean_dir.mkdir(parents=True, exist_ok=True)
    clean_files = []
    for original in original_files:
        content = original.read_text(encoding="utf-8-sig")
        tokens = preprocess(content, stop_words, english_words, lemmatizer)
        if not tokens:
            raise ValueError(f"El texto quedó vacío tras la limpieza: {original.name}")
        cleaned = clean_dir / f"{original.stem}_limpio.txt"
        write_text(cleaned, " ".join(tokens))
        clean_files.append(cleaned)

    # 2. Relectura de los TXT producidos en esta ejecución.
    names = [path.name for path in clean_files]
    documents = [path.read_text(encoding="utf-8").split() for path in clean_files]
    per_document_unigrams = [Counter(tokens) for tokens in documents]
    per_document_bigrams = [Counter(zip(tokens, tokens[1:])) for tokens in documents]

    global_unigrams = Counter()
    global_bigrams = Counter()
    for uc, bc in zip(per_document_unigrams, per_document_bigrams):
        global_unigrams.update(uc)
        global_bigrams.update(bc)

    total_tokens = sum(global_unigrams.values())
    total_bigrams = sum(global_bigrams.values())
    if expected_documents == EXPECTED_DOCUMENTS and (
        total_tokens != ARCHIVED_TOKENS or total_bigrams != ARCHIVED_BIGRAMS
    ):
        raise ValueError(
            "El corpus procesado no coincide con la versión Top-100 archivada: "
            f"se obtuvieron {total_tokens} tokens y {total_bigrams} bigramas; "
            f"se esperaban {ARCHIVED_TOKENS} y {ARCHIVED_BIGRAMS}. "
            "Revise los TXT originales y los recursos de NLTK. "
            "No se generó un Excel con resultados incompatibles."
        )

    top_unigrams = global_unigrams.most_common(TOP_N)
    top_bigrams = global_bigrams.most_common(TOP_N)
    matrix_unigrams = make_matrix(names, per_document_unigrams, top_unigrams)
    matrix_bigrams = make_matrix(names, per_document_bigrams, top_bigrams, bigrams=True)
    write_workbook(excel_output, matrix_unigrams, matrix_bigrams)

    print(f"Artículos: {len(names)}; tokens: {total_tokens}; bigramas: {total_bigrams}")
    print(f"TXT limpios: {clean_dir}")
    print(f"Excel (solo unigramas y bigramas): {excel_output}")


def main():
    base_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--raw-dir", type=Path, default=base_dir / "seeds" / "raw")
    parser.add_argument("--clean-dir", type=Path)
    parser.add_argument("--excel-output", type=Path,
                        default=base_dir / "all_text_analysis_top100.xlsx")
    parser.add_argument("--expected-documents", type=int, default=EXPECTED_DOCUMENTS)
    args = parser.parse_args()
    run(args.raw_dir, args.clean_dir or args.raw_dir.parent,
        args.excel_output, args.expected_documents)


if __name__ == "__main__":
    main()
