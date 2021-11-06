<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" omit-xml-declaration="yes" />
    <xsl:param name="qty" />
    <xsl:template match="/">
\documentclass[a4paper,10pt]{article}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{xcolor}
\usepackage{tabularx}

\begin{document}
<xsl:if test="count(flights_data/error) > 0">
    {
        \large
        <xsl:for-each select="flights_data/error">
            \textcolor{red}{ERROR: <xsl:value-of select="." />}
        </xsl:for-each>
    }
</xsl:if>

<xsl:if test="count(flights_data/flight) > 0">
\hspace{-2.4cm}
\def\arraystretch{1.5}
\begin{tabular}{|l p{.12\textwidth} p{.12\textwidth} p{.12\textwidth} p{.30\textwidth} p{.30\textwidth}|}
    \textbf{Flight ID} &amp; \textbf{Country} &amp; \textbf{Position} &amp; \textbf{Status} &amp; \textbf{Departure Airport} &amp; \textbf{Arrival Airport}\\
    \hline
    <xsl:for-each select="flights_data/flight">
        <xsl:if test="not(position() > $qty)">
            <xsl:apply-templates select="." />
        </xsl:if>
    </xsl:for-each>
    \hline
\end{tabular}
</xsl:if>
\end{document}

    </xsl:template>

    <xsl:template name="flight" match="flight">
        <xsl:value-of select="@id" />&amp;<xsl:value-of select="country" /> &amp;<xsl:call-template name="position-format"><xsl:with-param name="position" select="position" /></xsl:call-template>&amp;<xsl:value-of select="status" />&amp; <xsl:value-of select="departure_airport/name" />&amp; <xsl:value-of select="arrival_airport/name" />\\
    </xsl:template>

    <xsl:template name="position-format">
        <xsl:param name="position" />
        (<xsl:value-of select="$position/lat" />, <xsl:value-of select="$position/lng" />)
    </xsl:template>
</xsl:stylesheet>

<!-- No se cual va primero, longitud o latitud -->