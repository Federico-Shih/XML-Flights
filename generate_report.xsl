<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="text" omit-xml-declaration="yes" />
    <xsl:param name="qty" />
    <xsl:template match="/">
\documentclass[a4paper,10pt]{article}
\usepackage{booktabs}
\usepackage{xcolor}

\definecolor{green}{RGB}{66, 186, 150}
\definecolor{blue}{RGB}{124, 105, 239}
\definecolor{orange}{RGB}{252, 171, 40}

\begin{document}
\title{Flight Report}
\author{XML Group 10}
\date{\today}
\maketitle
\newpage

<xsl:if test="count(flights_data/error) > 0">
{
    \large
    <xsl:for-each select="flights_data/error">
        \textcolor{red}{ERROR: <xsl:value-of select="." />}
    </xsl:for-each>
}
</xsl:if>

<xsl:if test="(string(number($qty)) = 'NaN')">
{
    \large
    \textcolor{red}{ERROR: qty NOT A NUMBER}
}
</xsl:if>

<xsl:if test="count(flights_data/flight) > 0 and (string(number($qty)) != 'NaN' or not($qty))">
\hspace{-2.4cm}
\def\arraystretch{1.5}
\begin{tabular}{@{} l p{.12\textwidth} p{.18\textwidth} p{.18\textwidth} p{.30\textwidth} p{.30\textwidth} @{}}
    \toprule
    \textbf{Flight ID} &amp; \textbf{Country} &amp; \textbf{Position} &amp; \textbf{Status} &amp; \textbf{Departure Airport} &amp; \textbf{Arrival Airport}\\
    \midrule\midrule
    <xsl:for-each select="flights_data/flight">
        <xsl:choose>
            <xsl:when test="not($qty)">
                <xsl:apply-templates select="." />
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="not(position() > $qty)">
                    <xsl:apply-templates select="." />
                </xsl:if>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:for-each>
    \bottomrule
\end{tabular}
</xsl:if>
\end{document}

    </xsl:template>

    <xsl:template name="flight" match="flight">
        <xsl:value-of select="@id" />&amp;<xsl:value-of select="country" /> &amp;<xsl:apply-templates select="position" />&amp;<xsl:apply-templates select="status" /> &amp; <xsl:value-of select="departure_airport/name" />&amp; <xsl:value-of select="arrival_airport/name" />\\
    </xsl:template>

    <xsl:template name="status" match="status">
        <xsl:param name="status" select="normalize-space(.)" />
        <xsl:choose>
            <xsl:when test="$status = 'landed'">
                \textcolor{green}{\textbf{landed}}
            </xsl:when>
            <xsl:when test="$status = 'en-route'">
                \textcolor{blue}{\textbf{en-route}}
            </xsl:when>
            <xsl:when test="$status = 'scheduled'">
                \textcolor{orange}{scheduled}
            </xsl:when>
            <xsl:otherwise>
                \textcolor{red}{<xsl:value-of select="$status" />}
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="position" match="position">
        (<xsl:value-of select="lat" />, <xsl:value-of select="lng" />)
    </xsl:template>
</xsl:stylesheet>

<!-- No se cual va primero, longitud o latitud -->