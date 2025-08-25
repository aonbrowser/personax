#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import plutoprint
import markdown2
from datetime import datetime
import os
import tempfile
import base64
from io import BytesIO

app = Flask(__name__)
CORS(app, origins=['http://localhost:8080', 'http://localhost:8081', 'https://personax.app'])

# Read logo and convert to base64
logo_path = os.path.join(os.path.dirname(__file__), 'cogni-coach-logo.png')
logo_base64 = ""
if os.path.exists(logo_path):
    with open(logo_path, 'rb') as logo_file:
        logo_base64 = base64.b64encode(logo_file.read()).decode('utf-8')

def markdown_to_html(markdown_text):
    """Convert markdown to HTML with Turkish character support"""
    
    # Convert markdown to HTML
    html_content = markdown2.markdown(
        markdown_text,
        extras=['fenced-code-blocks', 'tables', 'break-on-newline']
    )
    
    # Create full HTML document with proper styling
    html_template = f"""
    <!DOCTYPE html>
    <html lang="tr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
            
            * {{
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }}
            
            body {{
                font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                color: #2d3748;
                padding: 40px;
                max-width: 800px;
                margin: 0 auto;
                background: white;
            }}
            
            .header {{
                text-align: center;
                margin-bottom: 40px;
                padding-bottom: 30px;
                border-bottom: 3px solid #60BBCA;
            }}
            
            .logo-img {{
                max-width: 200px;
                height: auto;
                margin-bottom: 20px;
            }}
            
            .report-title {{
                font-size: 24px;
                font-weight: 600;
                color: #1a202c;
                margin-bottom: 10px;
            }}
            
            .report-date {{
                font-size: 14px;
                color: #718096;
            }}
            
            .content {{
                margin-top: 30px;
            }}
            
            h1 {{
                font-size: 24px;
                font-weight: 700;
                color: #1a202c;
                margin: 30px 0 15px 0;
                padding-bottom: 10px;
                border-bottom: 2px solid #e2e8f0;
            }}
            
            h2 {{
                font-size: 20px;
                font-weight: 600;
                color: #2d3748;
                margin: 25px 0 12px 0;
            }}
            
            h3 {{
                font-size: 16px;
                font-weight: 600;
                color: #4a5568;
                margin: 20px 0 10px 0;
            }}
            
            p {{
                font-size: 14px;
                line-height: 1.8;
                color: #4a5568;
                margin-bottom: 12px;
                text-align: justify;
            }}
            
            ul, ol {{
                margin: 12px 0 12px 20px;
                padding-left: 10px;
            }}
            
            li {{
                font-size: 14px;
                line-height: 1.8;
                color: #4a5568;
                margin-bottom: 8px;
            }}
            
            strong {{
                font-weight: 600;
                color: #2d3748;
            }}
            
            em {{
                font-style: italic;
                color: #4a5568;
            }}
            
            blockquote {{
                border-left: 4px solid #60BBCA;
                padding-left: 20px;
                margin: 20px 0;
                font-style: italic;
                color: #4a5568;
            }}
            
            .section {{
                background: #f7fafc;
                padding: 20px;
                border-radius: 8px;
                margin: 20px 0;
                border: 1px solid #e2e8f0;
            }}
            
            .footer {{
                margin-top: 50px;
                padding-top: 20px;
                border-top: 2px solid #e2e8f0;
                text-align: center;
                color: #718096;
                font-size: 12px;
            }}
            
            @page {{
                size: A4;
                margin: 15mm;
            }}
            
            @media print {{
                body {{
                    padding: 0;
                }}
                
                h1, h2, h3 {{
                    page-break-after: avoid;
                }}
                
                p, li {{
                    orphans: 3;
                    widows: 3;
                }}
                
                .section {{
                    page-break-inside: avoid;
                }}
            }}
        </style>
    </head>
    <body>
        <div class="header">
            <img src="data:image/png;base64,{logo_base64}" alt="Cogni Coach" class="logo-img" />
            <div class="report-title">Kişisel Analiz Raporu</div>
            <div class="report-date">{datetime.now().strftime('%d %B %Y, %A')}</div>
        </div>
        
        <div class="content">
            {html_content}
        </div>
        
        <div class="footer">
            <p>© {datetime.now().year} Cogni Coach - Tüm hakları saklıdır</p>
            <p>Bu rapor kişisel kullanım içindir ve gizlilik esaslarına tabidir.</p>
        </div>
    </body>
    </html>
    """
    
    return html_template

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'service': 'pdf-generator'})

@app.route('/generate-pdf', methods=['POST'])
def generate_pdf():
    try:
        data = request.json
        markdown_text = data.get('markdown', '')
        
        if not markdown_text:
            return jsonify({'error': 'No markdown content provided'}), 400
        
        # Convert markdown to HTML
        html_content = markdown_to_html(markdown_text)
        
        # Create temporary HTML file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.html', delete=False, encoding='utf-8') as html_file:
            html_file.write(html_content)
            html_path = html_file.name
        
        # Create temporary PDF file
        pdf_path = tempfile.mktemp(suffix='.pdf')
        
        try:
            # Generate PDF using PlutoPrint
            book = plutoprint.Book(plutoprint.PAGE_SIZE_A4)
            book.load_url(f"file://{html_path}")
            book.write_to_pdf(pdf_path)
            
            # Read PDF and return as base64
            with open(pdf_path, 'rb') as pdf_file:
                pdf_data = pdf_file.read()
                pdf_base64 = base64.b64encode(pdf_data).decode('utf-8')
            
            # Clean up temporary files
            os.unlink(html_path)
            os.unlink(pdf_path)
            
            return jsonify({
                'success': True,
                'pdf': pdf_base64,
                'filename': f"Cogni_Coach_Analiz_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            })
            
        except Exception as e:
            # Clean up on error
            if os.path.exists(html_path):
                os.unlink(html_path)
            if os.path.exists(pdf_path):
                os.unlink(pdf_path)
            raise e
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/generate-pdf-file', methods=['POST'])
def generate_pdf_file():
    """Alternative endpoint that returns PDF as file download"""
    try:
        data = request.json
        markdown_text = data.get('markdown', '')
        
        if not markdown_text:
            return jsonify({'error': 'No markdown content provided'}), 400
        
        # Convert markdown to HTML
        html_content = markdown_to_html(markdown_text)
        
        # Create temporary HTML file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.html', delete=False, encoding='utf-8') as html_file:
            html_file.write(html_content)
            html_path = html_file.name
        
        # Create temporary PDF file
        pdf_path = tempfile.mktemp(suffix='.pdf')
        
        try:
            # Generate PDF using PlutoPrint
            book = plutoprint.Book(plutoprint.PAGE_SIZE_A4)
            book.load_url(f"file://{html_path}")
            book.write_to_pdf(pdf_path)
            
            # Clean up HTML file
            os.unlink(html_path)
            
            # Send PDF file
            return send_file(
                pdf_path,
                mimetype='application/pdf',
                as_attachment=True,
                download_name=f"Cogni_Coach_Analiz_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
            )
            
        except Exception as e:
            # Clean up on error
            if os.path.exists(html_path):
                os.unlink(html_path)
            if os.path.exists(pdf_path):
                os.unlink(pdf_path)
            raise e
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)