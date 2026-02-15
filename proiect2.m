clc
clear all
close all

load("iddata-01.mat");

id.u = id.InputData{1};
id.y = id.OutputData{1};
val.u = val.InputData{1};
val.y = val.OutputData{1};

figure(1)
subplot(2, 1, 1)
plot(id.u);
title('identificare - intrari');
grid on; 

subplot(2, 1, 2)
plot(id.y);
title('identificare - iesiri');
grid on;

figure(2)
subplot(2, 1, 1)
plot(val.u);
title('validare - intrari');
grid on; 

subplot(2, 1, 2)
plot(val.y);
title('validare - iesiri');
grid on

%model narx de ordin n
na = 6;
nb = 6;
m = 3;
nk = 1;

%generare de regresori
phi_id = generareRegresori(id, na, nb, m);
Y = id.y(max(na, nb) + 1 : end);

theta = phi_id \ Y;

%predictie
y_pred_id  = predictie(id.u, id.y, theta, na, nb, m);
y_pred_val = predictie(val.u, val.y, theta, na, nb, m);

figure(3)
subplot(2, 1, 1);
plot(id.y); hold on;
plot(y_pred_id);
legend("real", "predicite");
title('date de identificare - predictie');

subplot(2, 1, 2);
plot(val.y); hold on;
plot(y_pred_val);
legend("real", "predicite");
title('date de validare - predictie');

%simulare
y_sim_id  = simulare(id.u, id.y, theta, na, nb, m);
y_sim_val = simulare(val.u, val.y, theta, na, nb, m);

figure(4)
subplot(2, 1, 1);
plot(id.y); hold on;
plot(y_sim_id);
legend("real", "simulare");
title('date de identificare - simulare');

subplot(2, 1, 2);
plot(val.y); hold on;
plot(y_sim_val);
legend("real", "simulare");
title('date de validare - simulare');

%compareare cu model narx
id_data = iddata(id.y, id.u);
val_data = iddata(val.y, val.u);

model_narx = nlarx(id_data, [na nb nk]);

figure(5)
subplot(2, 1, 1)
compare(id_data, model_narx);
title('compare - identificare');

subplot(2, 1, 2)
compare(val_data, model_narx);
title('compare - validare');

%mse

mse_pred_id = mean((id.y - y_pred_id).^2);
mse_sim_id  = mean((id.y - y_sim_id).^2);
mse_pred_val = mean((val.y - y_pred_val).^2);
mse_sim_val  = mean((val.y - y_sim_val).^2);

%testare
na_values = 1:8;
m_values  = 1:3;
best_mse = inf;
best_na = NaN;
best_nb = NaN;
best_m  = NaN;
best_theta = [];

MSE_pred_id  = zeros(length(na_values), length(m_values));
MSE_sim_id   = zeros(length(na_values), length(m_values));
MSE_pred_val = zeros(length(na_values), length(m_values));
MSE_sim_val  = zeros(length(na_values), length(m_values));

for i_na = 1:length(na_values)
    na = na_values(i_na);
    nb = na;   % pentru simplitate, conform cerintei

    for i_m = 1:length(m_values)
        m = m_values(i_m);

        phi_id = generareRegresori(id, na, nb, m);
        Y = id.y(max(na, nb)+1:end);

        theta = phi_id \ Y;

        % predictie
        y_pred_id  = predictie(id.u, id.y, theta, na, nb, m);
        y_pred_val = predictie(val.u, val.y, theta, na, nb, m);

        % simulare
        y_sim_id  = simulare(id.u, id.y, theta, na, nb, m);
        y_sim_val = simulare(val.u, val.y, theta, na, nb, m);

        % MSE
        MSE_pred_id(i_na,i_m)  = mean((id.y - y_pred_id).^2);
        MSE_sim_id(i_na,i_m) = mean((id.y - y_sim_id).^2);
        MSE_pred_val(i_na,i_m) = mean((val.y - y_pred_val).^2);
        MSE_sim_val(i_na,i_m) = mean((val.y - y_sim_val).^2);


        % alegem simularea pe validare ca criteriu de selectie a erorii
        % minime, intrucat este cea mai sensibila
        if MSE_sim_val(i_na, i_m) < best_mse
            best_mse = MSE_sim_val(i_na, i_m);
            best_na = na;
            best_nb = nb;
            best_m  = m;
            best_theta = theta;
        end
    end
end

titluri = {'Identificare - Predicție', 'Identificare - Simulare', ...
           'Validare - Predicție',     'Validare - Simulare'};
matrici = {MSE_pred_id, MSE_sim_id, MSE_pred_val, MSE_sim_val};

for k = 1:4
    fprintf('\n==============================================\n');
    fprintf('   MSE: %s\n', titluri{k});
    fprintf('==============================================\n');
    
    % Afisare cap de tabel (valorile lui m)
    fprintf('      '); % spatiu pentru eticheta de rand
    for m = m_values
        fprintf('    m=%d   ', m);
    end
    fprintf('\n');
    
    % Afisare continut
    for i = 1:length(na_values)
        fprintf('na=%d |', na_values(i)); % Eticheta randului (na)
        for j = 1:length(m_values)
            % Accesam matricea curenta matrici{k}
            matrice_curenta = matrici{k};
            fprintf('%9.4f ', matrice_curenta(i, j));
        end
        fprintf('\n');
    end
end

fprintf('\nMODEL OPTIM SELECTAT\n');
fprintf('na = nb = %d\n', best_na);
fprintf('m  = %d\n', best_m);
fprintf('MSE simulare validare = %.6f\n', best_mse);

function y_pred = predictie(u, y, theta, na, nb, m)
    N = length(y);
    y_pred = y;

    for k = max(na,nb)+1:N
        d = [int(y,k,na); int(u,k,nb)];

        col = 1;
        val = 0;
        for i = 1:length(d)
            for p = 0:m
                for q = 0:(m-p)
                    val = val + theta(col) * d(i)^p * d(i)^q;
                    col = col + 1;
                end
            end
        end
        y_pred(k) = val;
    end
end

function y_sim = simulare(u, y, theta, na, nb, m)
    N = length(y);
    y_sim = y;

    for k = max(na,nb)+1:N
        d = [int(y_sim,k,na); int(u,k,nb)];

        col = 1;
        val = 0;
        for i = 1:length(d)
            for p = 0:m
                for q = 0:(m-p)
                    val = val + theta(col) * d(i)^p * d(i)^q;
                    col = col + 1;
                end
            end
        end
        y_sim(k) = val;
    end
end


function phi_data = generareRegresori(data, na, nb, m)
    u = data.u;
    y = data.y;
    N = length(y);

    k0 = max(na, nb) + 1;

    % vector de regresori: y + u
    r = na + nb;

    % nr termeni polinomiali (ca la tine)
    n_poly = (m+1)*(m+2)/2;

    phi_data = zeros(N - k0 + 1, n_poly * r);

    row = 1;
    for k = k0:N
        y_int = int(y, k, na);
        u_int = int(u, k, nb);

        d = [y_int; u_int];   % <-- AICI e cheia

        col = 1;
        for i = 1:length(d)
            for p = 0:m
                for q = 0:(m-p)
                    phi_data(row, col) = d(i)^p * d(i)^q;
                    col = col + 1;
                end
            end
        end
        row = row + 1;
    end
end

function v = int(x, k, n)
    v = zeros(n,1);
    for i = 1:n
        if (k - i) > 0
            v(i) = x(k - i);
        else
            v(i) = 0;
        end
    end
end