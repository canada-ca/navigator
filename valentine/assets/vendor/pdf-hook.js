import { jsPDF } from "jspdf";

const PDFHook = {
    mounted() {
        console.log('PDFHook mounted');
        this.handleEvent('download_pdf', () => {
            console.log('Downloading PDF...');

            const doc = new jsPDF();

            doc.fromHTML(this.el, 10, 10, { 'width': 180 });
            doc.autoPrint();
            doc.output("dataurlnewwindow"); // this opens a new popup,  after this the PDF opens the print window view but there are browser inconsistencies with how this is handled
        });
    }
}

export default PDFHook;