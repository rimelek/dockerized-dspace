<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" >
    <xsl:output encoding="utf-8" />
    <xsl:output indent="yes" />

    <xsl:param name="DS_REDIS_SESSION" >false</xsl:param>

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="/Context">
        <Context>
            <xsl:copy-of select="./*" />
            <xsl:if test="$DS_REDIS_SESSION = 'true'">
                <Manager className="org.redisson.tomcat.RedissonSessionManager" updateMode="AFTER_REQUEST">
                    <xsl:attribute name="configPath">/app/tomcat/conf/redisson.yaml</xsl:attribute>
                </Manager>
            </xsl:if>
        </Context>

    </xsl:template>

</xsl:stylesheet>